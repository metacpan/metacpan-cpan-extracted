package Database::Abstraction;

# Author Nigel Horne: njh@nigelhorne.com
# Copyright (C) 2015-2025, Nigel Horne

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (for example, Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

# TODO:	Switch "entry" to off by default, and enable by passing 'entry'
#	though that wouldn't be so nice for AUTOLOAD
# TODO:	support a directory hierarchy of databases
# TODO:	consider returning an object or array of objects, rather than hashes
# TODO:	Add redis database - could be of use for Geo::Coder::Free
#	use select() to select a database - use the table arg
#	new(database => 'redis://servername');
# TODO:	Add a "key" property, defaulting to "entry", which would be the name of the key
# TODO:	The maximum number to return should be tuneable (as a LIMIT)
# TODO:	Add full CRUD support
# TODO:	It would be better for the default sep_char to be ',' rather than '!'
# FIXME:	t/xml.t fails in slurping mode
# TODO:	Other databases e.g., Redis, noSQL, remote databases such as MySQL, PostgresSQL
# TODO: The no_entry/entry terminology is confusing.  Replace with no_id/id_column
# TODO: Add support for DBM::Deep
# TODO: Log queries and the time that they took to execute per database

use warnings;
use strict;

use boolean;
use Carp;
use Data::Dumper;
use Data::Reuse;
use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use Fcntl;	# For O_RDONLY
use File::Spec;
use File::pfopen 0.03;	# For $mode and list context
use File::Temp;
use Log::Abstraction 0.26;
use Object::Configure 0.16;
use Params::Get 0.13;
# use Error::Simple;	# A nice idea to use this, but it doesn't play well with "use lib"
use Scalar::Util;

our %defaults;
use constant	DEFAULT_MAX_SLURP_SIZE => 16 * 1024;	# CSV files <= than this size are read into memory

=head1 NAME

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

=head1 VERSION

Version 0.33

=cut

our $VERSION = '0.33';

=head1 DESCRIPTION

C<Database::Abstraction> is a read-only database abstraction layer (ORM) for Perl,
designed to provide a simple interface for accessing and querying various types of databases such as CSV, XML, and SQLite without the need to write SQL queries.
It promotes code maintainability by abstracting database access logic into a single interface,
allowing users to switch between different storage formats seamlessly.
The module supports caching for performance optimization,
flexible logging for debugging and monitoring,
and includes features like the AUTOLOAD method for convenient access to database columns.
By handling numerous database and file formats,
C<Database::Abstraction> adds versatility and simplifies the management of read-intensive applications.

=head1 SYNOPSIS

Abstract class giving read-only access to CSV,
XML,
BerkeleyDB and SQLite databases via Perl without writing any SQL,
using caching for performance optimization.

The module promotes code maintainability by abstracting database access logic into a single interface.
Users can switch between different storage formats without changing application logic.
The ability to handle numerous database and file formats adds versatility and makes it useful for a variety of applications.

It's a simple ORM like interface which,
for all of its simplicity,
allows you to do a lot of the heavy lifting of simple database operations without any SQL.
It offers functionalities like opening the database and fetching data based on various criteria.

Built-in support for flexible and configurable caching improves performance for read-intensive applications.

Supports logging to debug and monitor database operations.

Look for databases in $directory in this order:

=over 4

=item 1 C<SQLite>

File ends with .sql

=item 2 C<PSV>

Pipe separated file, file ends with .psv

=item 3 C<CSV>

File ends with .csv or .db, can be gzipped. Note the default sep_char is '!' not ','

=item 4 C<XML>

File ends with .xml

=item 5 C<BerkeleyDB>

File ends with .db

=back

The AUTOLOAD feature allows for convenient access to database columns using method calls.
It hides the complexity of querying the underlying data storage.

If the table has a key column,
entries are keyed on that and sorts are based on it.
To turn that off, pass 'no_entry' to the constructor, for legacy
reasons it's enabled by default.
The key column's default name is 'entry', but it can be overridden by the 'id' parameter.

Arrays are made read-only before being returned.
To disable that, pass C<no_fixate> to the constructor.

CSV files that are not no_entry can have empty lines or comment lines starting with '#',
to make them more readable.

=head1 EXAMPLE

If the file /var/dat/foo.csv contains something like:

    "customer_id","name"
    "plugh","John"
    "xyzzy","Jane"

Create a driver for the file in .../Database/foo.pm:

    package Database::foo;

    use Database::Abstraction;

    our @ISA = ('Database::Abstraction');

    # Regular CSV: There is no entry column and the separators are commas
    sub new
    {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

You can then use this code to access the data via the driver:

    # Opens the file, e.g. /var/dat/foo.csv
    my $foo = Database::foo->new(directory => '/var/dat');

    # Prints "John"
    print 'Customer name ', $foo->name(customer_id => 'plugh'), "\n";

    # Prints:
    #  $VAR1 = {
    #     'customer_id' => 'xyzzy',
    #     'name' => 'Jane'
    #  };
    my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');
    print Data::Dumper->new([$row])->Dump();

=head1 SUBROUTINES/METHODS

=head2 init

Initializes the abstraction class and its subclasses with optional arguments for configuration.

    Database::Abstraction::init(directory => '../data');

See the documentation for new to see what variables can be set.

Returns a reference to a hash of the current values.
Therefore when given with no arguments you can get the current default values:

    my $defaults = Database::Abstraction::init();
    print $defaults->{'directory'}, "\n";

=cut

# Subroutine to initialize with args
sub init
{
	if(my $params = Params::Get::get_params(undef, @_)) {
		if(($params->{'expires_in'} && !$params->{'cache_duration'})) {
			# Compatibility with CHI
			$params->{'cache_duration'} = $params->{'expires_in'};
		}

		%defaults = (%defaults, %{$params});
		$defaults{'cache_duration'} ||= '1 hour';
	}

	return \%defaults
}

=head2 import

The module can be initialised by the C<use> directive.

    use Database::Abstraction 'directory' => '/etc/data';

or

    use Database::Abstraction { 'directory' => '/etc/data' };

=cut

sub import
{
	my $pkg = shift;

	if((scalar(@_) % 2) == 0) {
		my %h = @_;
		init(Object::Configure::configure($pkg, \%h));
	} elsif((scalar(@_) == 1) && (ref($_[0]) eq 'HASH')) {
		init(Object::Configure::configure($pkg, $_[0]));
	} elsif(scalar(@_) > 0) {	# >= 3 would also work here
		init(\@_);
	}
}

=head2 new

Create an object to point to a read-only database.

Arguments:

Takes different argument formats (hash or positional)

=over 4

=item * C<auto_load>

Enable/disable the AUTOLOAD feature.
The default is to have it enabled.

=item * C<cache>

Place to store results

=item * C<cache_duration>

How long to store results in the cache (default is 1 hour).

=item * C<config_file>

Points to a configuration file which contains the parameters to C<new()>.
The file can be in any common format including C<YAML>, C<XML>, and C<INI>.
This allows the parameters to be set at run time.

=item * C<expires_in>

Synonym of C<cache_duration>, for compatibility with C<CHI>.

=item * C<dbname>

The prefix of name of the database file (default is name of the table).
The database will be held in a file such as $dbname.csv.

=item * C<directory>

Where the database file is held.
If only one argument is given to C<new()>, it is taken to be C<directory>.

=item * C<filename>

Filename containing the data.
When not given,
the filename is derived from the tablename
which in turn comes from the class name.

=item * C<logger>

Takes an optional parameter logger, which is used for warnings and traces.
Can be an object that understands warn() and trace() messages,
such as a L<Log::Log4perl> or L<Log::Any> object,
a reference to code,
or a filename.

=item * C<max_slurp_size>

CSV/PSV/XML files smaller than this are held in a HASH in RAM (default is 16K),
falling back to SQL on larger data sets.
Setting this value to 0 will turn this feature off,
thus forcing SQL to be used to access the database

=back

If the arguments are not set, tries to take from class level defaults.

Checks for abstract class usage.

Slurp mode assumes that the key column (entry) is unique.
If it isn't, searches will be incomplete.
Turn off slurp mode on those databases,
by setting a low value for max_slurp_size.

Clones existing objects with or without modifications.
Uses Carp::carp to log warnings for incorrect usage or potential mistakes.

=cut

sub new {
	my $class = shift;
	my %args;

	# Handle hash or hashref arguments
	if((scalar(@_) == 1) && !ref($_[0])) {
		$args{'directory'} = $_[0];
	} elsif(my $params = Params::Get::get_params(undef, @_)) {
		%args = %{$params};
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using Database::Abstraction->new(), not Database::Abstraction::new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif($class eq __PACKAGE__) {
		croak("$class: abstract class");
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	# Load the configuration from a config file, if provided
	%args = %{Object::Configure::configure($class, \%args)};

	# Validate logger object has required methods
	if(defined $args{'logger'}) {
		unless(Scalar::Util::blessed($args{'logger'}) && $args{'logger'}->can('info') && $args{'logger'}->can('error')) {
			Carp::croak("Logger must be an object with info() and error() methods");
		}
	}

	croak("$class: where are the files?") unless($args{'directory'} || $defaults{'directory'});

	croak("$class: ", $args{'directory'} || $defaults{'directory'}, ' is not a directory') unless(-d ($args{'directory'} || $defaults{'directory'}));

	# init(\%args);

	# return bless {
		# logger => $args{'logger'} || $logger,
		# directory => $args{'directory'} || $directory,	# The directory containing the tables in XML, SQLite or CSV format
		# cache => $args{'cache'} || $cache,
		# cache_duration => $args{'cache_duration'} || $cache_duration || '1 hour',
		# table => $args{'table'},	# The name of the file containing the table, defaults to the class name
		# no_entry => $args{'no_entry'} || 0,
	# }, $class;

	# Re-seen keys take precedence, so defaults come first
	# print STDERR ">>>>>>>>>>>>>>>>>>>\n";
	# print STDERR __LINE__, "\n";
	# print STDERR $args{'id'} || 'undef';
	# print STDERR "\n";
	return bless {
		no_entry => 0,
		no_fixate => 0,
		id => 'entry',
		cache_duration => '1 hour',
		max_slurp_size => DEFAULT_MAX_SLURP_SIZE,
		%defaults,
		%args,
	}, $class;
}

=head2	set_logger

Sets the class, code reference, or file that will be used for logging.

=cut

sub set_logger
{
	my $self = shift;
	my $params = Params::Get::get_params('logger', @_);

	if(my $logger = ($params->{'logger'})) {
		if(Scalar::Util::blessed($logger)) {
			$self->{'logger'} = $logger;
		} else {
			$self->{'logger'} = Log::Abstraction->new($logger);
		}
		return $self;
	}
	Carp::croak('Usage: set_logger(logger => $logger)')
}

# Open the database connection based on the specified type (e.g., SQLite, CSV).
# Read the data into memory or establish a connection to the database file.
# column_names allows the column names to be overridden on CSV files

sub _open
{
	if(!UNIVERSAL::isa((caller)[0], __PACKAGE__)) {
		Carp::croak('Illegal Operation: This method can only be called by a subclass');
	}

	my $self = shift;
	my $params = Params::Get::get_params(undef, @_);

	$params->{'sep_char'} ||= $self->{'sep_char'} ? $self->{'sep_char'} : '!';
	my $max_slurp_size = $params->{'max_slurp_size'} || $self->{'max_slurp_size'};

	my $table = $self->{'table'} || ref($self);
	$table =~ s/.*:://;

	$self->_trace(ref($self), ": _open $table");

	return if($self->{$table});

	# Read in the database
	my $dbh;

	my $dir = $self->{'directory'} || $defaults{'directory'};
	my $dbname = $self->{'dbname'} || $defaults{'dbname'} || $table;
	my $slurp_file = File::Spec->catfile($dir, "$dbname.sql");

	$self->_debug("_open: try to open $slurp_file");

	# Look at various places to find the file and derive the file type from the file's name
	if(-r $slurp_file) {
		# SQLite file
		require DBI && DBI->import() unless DBI->can('connect');

		$dbh = DBI->connect("dbi:SQLite:dbname=$slurp_file", undef, undef, {
			sqlite_open_flags => SQLITE_OPEN_READONLY,
		});
	}
	if($dbh) {
		$dbh->do('PRAGMA synchronous = OFF');
		$dbh->do('PRAGMA cache_size = -4096');	# Use 4MB cache - negative = KB)
		$dbh->do('PRAGMA journal_mode = OFF');	# Read-only, no journal needed
		$dbh->do('PRAGMA temp_store = MEMORY');	# Store temp data in RAM
		$dbh->do('PRAGMA mmap_size = 1048576');	# Use 1MB memory-mapped I/O
		$dbh->sqlite_busy_timeout(100000);	# 10s
		$self->_debug("read in $table from SQLite $slurp_file");
		$self->{'type'} = 'DBI';
	} elsif($self->_is_berkeley_db(File::Spec->catfile($dir, "$dbname.db"))) {
		$self->_debug("$table is a BerkeleyDB file");
		$self->{'type'} = 'BerkeleyDB';
	} else {
		my $fin;
		($fin, $slurp_file) = File::pfopen::pfopen($dir, $dbname, 'csv.gz:db.gz', '<');
		if(defined($slurp_file) && (-r $slurp_file)) {
			require Gzip::Faster;
			Gzip::Faster->import();

			close($fin);
			$fin = File::Temp->new(SUFFIX => '.csv', UNLINK => 0);
			print $fin gunzip_file($slurp_file);
			$slurp_file = $fin->filename();
			$self->{'temp'} = $slurp_file;
		} else {
			($fin, $slurp_file) = File::pfopen::pfopen($dir, $dbname, 'psv', '<');
			if(defined($fin)) {
				# Pipe separated file
				$params->{'sep_char'} = '|';
			} else {
				# CSV file
				($fin, $slurp_file) = File::pfopen::pfopen($dir, $dbname, 'csv:db', '<');
			}
		}
		if(my $filename = $self->{'filename'} || $defaults{'filename'}) {
			$self->_debug("Looking for $filename in $dir");
			$slurp_file = File::Spec->catfile($dir, $filename);
		}
		if(defined($slurp_file) && (-r $slurp_file)) {
			close($fin) if(defined($fin));
			my $sep_char = $params->{'sep_char'};

			$self->_debug(__LINE__, ' of ', __PACKAGE__, ": slurp_file = $slurp_file, sep_char = $sep_char");

			if($params->{'column_names'}) {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef,
					{
						csv_sep_char => $sep_char,
						csv_tables => {
							$table => {
								col_names => $params->{'column_names'},
							},
						},
					}
				);
			} else {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef, { csv_sep_char => $sep_char});
			}
			$dbh->{'RaiseError'} = 1;

			$self->_debug("read in $table from CSV $slurp_file");

			$dbh->{csv_tables}->{$table} = {
				allow_loose_quotes => 1,
				blank_is_undef => 1,
				empty_is_undef => 1,
				binary => 1,
				f_file => $slurp_file,
				escape_char => '\\',
				sep_char => $sep_char,
				# Don't do this, causes "Bizarre copy of HASH
				#	in scalar assignment in error_diag
				#	RT121127
				# auto_diag => 1,
				auto_diag => 0,
				# Don't do this, it causes "Attempt to free unreferenced scalar"
				# callbacks => {
					# after_parse => sub {
						# my ($csv, @rows) = @_;
						# my @rc;
						# foreach my $row(@rows) {
							# if($row->[0] !~ /^#/) {
								# push @rc, $row;
							# }
						# }
						# return @rc;
					# }
				# }
			};

			# my %options = (
				# allow_loose_quotes => 1,
				# blank_is_undef => 1,
				# empty_is_undef => 1,
				# binary => 1,
				# f_file => $slurp_file,
				# escape_char => '\\',
				# sep_char => $sep_char,
			# );

			# $dbh->{csv_tables}->{$table} = \%options;
			# delete $options{f_file};

			# require Text::CSV::Slurp;
			# Text::CSV::Slurp->import();
			# $self->{'data'} = Text::CSV::Slurp->load(file => $slurp_file, %options);

			# Can't slurp when we want to use our own column names as Text::xSV::Slurp has no way to override the names
			# FIXME: Text::xSV::Slurp can't cope well with quotes in field contents
			if(((-s $slurp_file) <= $max_slurp_size) && !$params->{'column_names'}) {
				if((-s $slurp_file) == 0) {
					# Empty file
					$self->{'data'} = ();
				} else {
					require Text::xSV::Slurp;
					Text::xSV::Slurp->import();

					$self->_debug('slurp in');

					my $dataref = xsv_slurp(
						shape => 'aoh',
						text_csv => {
							sep_char => $sep_char,
							allow_loose_quotes => 1,
							blank_is_undef => 1,
							empty_is_undef => 1,
							binary => 1,
							escape_char => '\\',
						},
						# string => \join('', grep(!/^\s*(#|$)/, <DATA>))
						file => $slurp_file
					);

					# Ignore blank lines or lines starting with # in the CSV file
					my @data = grep { $_->{$self->{'id'}} !~ /^\s*#/ } grep { defined($_->{$self->{'id'}}) } @{$dataref};

					if($self->{'no_entry'}) {
						# Not keyed, will need to scan each entry
						$self->{'data'} = @data;
					} else {
						# keyed on the $self->{'id'} (default: "entry") column
						# while(my $d = shift @data) {
							# $self->{'data'}->{$d->{$self->{'id'}}} = $d;
						# }
						# Build hash directly from the filtered array, better to use map to avoid data copy
						# and enclose in { } to ensure it's a hash ref
						$self->{'data'} = { map { $_->{$self->{'id'}} => $_ } @data };
					}
				}
			}
			$self->{'type'} = 'CSV';
		} else {
			$slurp_file = File::Spec->catfile($dir, "$dbname.xml");
			if(-r $slurp_file) {
				if((-s $slurp_file) <= $max_slurp_size) {
					require XML::Simple;
					XML::Simple->import();

					my $xml = XMLin($slurp_file);
					my @keys = keys %{$xml};
					my $key = $keys[0];
					my @data;
					if(ref($xml->{$key}) eq 'ARRAY') {
						@data = @{$xml->{$key}};
					} elsif(ref($xml) eq 'ARRAY') {
						@data = @{$xml};
					} elsif((ref($xml) eq 'HASH') && !$self->{'no_entry'}) {
						if(scalar(keys %{$xml}) == 1) {
							if($xml->{$table}) {
								@data = $xml->{$table};
							} else {
								die 'TODO: import arbitrary XML with "entry" field';
							}
						} else {
							die 'TODO: import arbitrary XML (differnt number of keys)';
						}
					} else {
						die 'TODO: import arbitrary XML, cannot currently handle ', ref($xml);
					}
					$self->{'data'} = ();
					if($self->{'no_entry'}) {
						# Not keyed, will need to scan each entry
						my $i = 0;
						foreach my $d(@data) {
							$self->{'data'}->{$i++} = $d;
						}
					} else {
						# keyed on the $self->{'id'} (default: "entry") column
						foreach my $d(@data) {
							$self->{'data'}->{$d->{$self->{'id'}}} = $d;
						}
					}
				} else {
					$dbh = DBI->connect('dbi:XMLSimple(RaiseError=>1):');
					$dbh->{'RaiseError'} = 1;
					$self->_debug("read in $table from XML $slurp_file");
					$dbh->func($table, 'XML', $slurp_file, 'xmlsimple_import');
				}
			} else {
				# throw Error(-file => "$dir/$table");
				$self->_fatal("Can't find a file called '$dbname' for the table $table in $dir");
			}
			$self->{'type'} = 'XML';
		}
	}

	Data::Reuse::fixate(%{$self->{'data'}}) if($self->{'data'} && (ref($self->{'data'} eq 'HASH')));

	$self->{$table} = $dbh;
	my @statb = stat($slurp_file);
	$self->{'_updated'} = $statb[9];

	return $self;
}

=head2	selectall_arrayref

Returns a reference to an array of hash references of all the data meeting
the given criteria.

Note that since this returns an array ref,
optimisations such as "LIMIT 1" will not be used.

Use caching if that is available.

Returns undef if there are no matches.

=cut

sub selectall_arrayref {
	my $self = shift;
	my $params;

	if($self->{'no_entry'}) {
		$params = Params::Get::get_params(undef, \@_);
	} elsif(scalar(@_)) {
		$params = Params::Get::get_params('entry', @_);
	}

	if($self->{'berkeley'}) {
		$self->_fatal(ref($self), ': selectall_arrayref is meaningless on a NoSQL database');
	}

	my $table = $self->_open_table($params);

	if($self->{'data'}) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: selectall_arrayref fast track return");
			if(ref($self->{'data'}) eq 'HASH') {
				# $self->{'data'} looks like this:
				#	key1 => {
				#		entry => key1,
				#		field1 => value1,
				#		field2 => value2
				#	}, key2 => {
				#		entry => key2,
				#		field1 => valuea,
				#		field2 => valueb
				#	}
				$self->_debug("$table: returning ", scalar keys %{$self->{'data'}}, ' entries');
				if(scalar keys %{$self->{'data'}} <= 10) {
					$self->_debug(Dumper($self->{'data'}));
				}
				my @rc;
				foreach my $k (keys %{$self->{'data'}}) {
					push @rc, $self->{'data'}->{$k};
				}
				return Return::Set::set_return(\@rc, { type => 'arrayref' });
			}
			return Return::Set::set_return($self->{'data'}, { type => 'arrayref'});
			# my @rc = values %{$self->{'data'}};
			# return @rc;
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			return Return::Set::set_return([$self->{'data'}->{$params->{'entry'}}], { type => 'arrayref' });
		}
	}

	my $query;
	my $done_where = 0;

	if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
		$query = "SELECT * FROM $table WHERE entry IS NOT NULL AND entry NOT LIKE '#%'";
		$done_where = 1;
	} else {
		$query = "SELECT * FROM $table";
	}

	my @query_args;
	foreach my $c1(sort keys(%{$params})) {	# sort so that the key is always the same
		my $arg = $params->{$c1};
		if(ref($arg)) {
			# throw Error::Simple("$query: argument is not a string: " . ref($arg));
			$self->_fatal("selectall_arrayref(): $query: argument is not a string: ", ref($arg));
		}
		if(!defined($arg)) {
			my @call_details = caller(0);
			# throw Error::Simple("$query: value for $c1 is not defined in call from " .
				# $call_details[2] . ' of ' . $call_details[1]);
			Carp::croak("$query: value for $c1 is not defined in call from ",
				$call_details[2], ' of ', $call_details[1]);
		}

		my $keyword;
		if($done_where) {
			$keyword = 'AND';
		} else {
			$keyword = 'WHERE';
			$done_where = 1;
		}
		if($arg =~ /[%_]/) {
			$query .= " $keyword $c1 LIKE ?";
		} else {
			$query .= " $keyword $c1 = ?";
		}
		push @query_args, $arg;
	}
	if(!$self->{no_entry}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}

	if(defined($query_args[0])) {
		$self->_debug("selectall_arrayref $query: ", join(', ', @query_args));
	} else {
		$self->_debug("selectall_arrayref $query");
	}

	my $key;
	my $c;
	if($c = $self->{cache}) {
		$key = ref($self) . "::$query array";
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		if(my $rc = $c->get($key)) {
			$self->_debug('cache HIT');
			return $rc;	# We stored a ref to the array

			# This use of a temporary variable is to avoid
			#	"Implicit scalar context for array in return"
			# my @rc = @{$rc};
			# return @rc;
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare($query)) {
		$sth->execute(@query_args) ||
			# throw Error::Simple("$query: @query_args");
			croak("$query: @query_args");

		my $rc;
		while(my $href = $sth->fetchrow_hashref()) {
			push @{$rc}, $href if(scalar keys %{$href});
		}
		if($c) {
			$c->set($key, $rc, $self->{'cache_duration'});	# Store a ref to the array
		}

		Data::Reuse::fixate(@{$rc}) if(!$self->{'no_fixate'});

		return $rc;
	}
	$self->_warn("selectall_array failure on $query: @query_args");
	# throw Error::Simple("$query: @query_args");
	croak("$query: @query_args");

	# my @rc = grep { defined $_ } $self->selectall_array(@_);

	# return if(scalar(@rc) == 0);

	# Data::Reuse::fixate(@rc) if(!$self->{'no_fixate'});
	# return \@rc;
}

=head2	selectall_hashref

Deprecated misleading legacy name for selectall_arrayref.

=cut

sub selectall_hashref
{
	my $self = shift;
	return $self->selectall_arrayref(@_);
}

=head2	selectall_array

Similar to selectall_array but returns an array of hash references.

Con:	Copies more data around than selectall_arrayref
Pro:	Better determination of list vs scalar mode than selectall_arrayref by setting "LIMIT 1"

TODO:	Remove duplicated code

=cut

sub selectall_array
{
	my $self = shift;

	if($self->{'berkeley'}) {
		Carp::croak(ref($self), ': selectall_array is meaningless on a NoSQL database');
	}

	my $params = Params::Get::get_params(undef, \@_);
	my $table = $self->_open_table($params);

	if($self->{'data'}) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: selectall_array fast track return");
			if(ref($self->{'data'}) eq 'HASH') {
				return values %{$self->{'data'}};
			}
			return @{$self->{'data'}};
			# my @rc = values %{$self->{'data'}};
			# return @rc;
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			return $self->{'data'}->{$params->{'entry'}};
		}
	}

	my $query;
	my $done_where = 0;

	if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
		$query = "SELECT * FROM $table WHERE entry IS NOT NULL AND entry NOT LIKE '#%'";
		$done_where = 1;
	} else {
		$query = "SELECT * FROM $table";
	}

	my @query_args;
	foreach my $c1(sort keys(%{$params})) {	# sort so that the key is always the same
		my $arg = $params->{$c1};
		if(ref($arg)) {
			# throw Error::Simple("$query: argument is not a string: " . ref($arg));
			$self->_fatal("selectall_array(): $query: argument is not a string: ", ref($arg));
		}

		my $keyword;
		if($done_where) {
			$keyword = 'AND';
		} else {
			$keyword = 'WHERE';
			$done_where = 1;
		}
		if(!defined($arg)) {
			$query .= " $keyword $c1 IS NULL"
		} else {
			if($arg =~ /[%_]/) {
				$query .= " $keyword $c1 LIKE ?";
			} else {
				$query .= " $keyword $c1 = ?";
			}
			push @query_args, $arg;
		}
	}
	if(!$self->{no_entry}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}
	if(!wantarray) {
		$query .= ' LIMIT 1';
	}

	if(defined($query_args[0])) {
		$self->_debug("selectall_array $query: ", join(', ', @query_args));
	} else {
		$self->_debug("selectall_array $query");
	}

	my $key;
	my $c;
	if($c = $self->{cache}) {
		$key = ref($self) . '::' . $query;
		if(wantarray) {
			$key .= ' array';
		}
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		if(my $rc = $c->get($key)) {
			$self->_debug('cache HIT');
			return wantarray ? @{$rc} : $rc;	# We stored a ref to the array

			# This use of a temporary variable is to avoid
			#	"Implicit scalar context for array in return"
			# my @rc = @{$rc};
			# return @rc;
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare($query)) {
		$sth->execute(@query_args) ||
			# throw Error::Simple("$query: @query_args");
			croak("$query: @query_args");

		my $rc;
		while(my $href = $sth->fetchrow_hashref()) {
			return $href if(!wantarray);	# FIXME: Doesn't store in the cache
			push @{$rc}, $href;
		}
		if($c) {
			$c->set($key, $rc, $self->{'cache_duration'});	# Store a ref to the array
		}

		if($rc) {
			Data::Reuse::fixate(@{$rc}) if(!$self->{'no_fixate'});
			return @{$rc};
		}
		return;
	}
	$self->_warn("selectall_array failure on $query: @query_args");
	# throw Error::Simple("$query: @query_args");
	croak("$query: @query_args");
}

=head2	selectall_hash

Deprecated misleading legacy name for selectall_array.

=cut

sub selectall_hash
{
	my $self = shift;
	return $self->selectall_array(@_);
}

=head2	count

Return the number items/rows matching the given criteria

=cut

sub count
{
	my $self = shift;

	if($self->{'berkeley'}) {
		Carp::croak(ref($self), ': count is meaningless on a NoSQL database');
	}

	my $params = Params::Get::get_params(undef, \@_);
	my $table = $self->_open_table($params);

	if($self->{'data'}) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: count fast track return");
			if(ref($self->{'data'}) eq 'HASH') {
				return scalar keys %{$self->{'data'}};
			}
			return scalar @{$self->{'data'}};
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			return $self->{'data'}->{$params->{'entry'}} ? 1 : 0;
		}
	}

	my $query;
	my $done_where = 0;

	if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
		$query = "SELECT COUNT(*) FROM $table WHERE entry IS NOT NULL AND entry NOT LIKE '#%'";
		$done_where = 1;
	} elsif($self->{no_entry}) {
		$query = "SELECT COUNT(*) FROM $table";
	} else {
		$query = "SELECT COUNT(entry) FROM $table";
	}

	my @query_args;
	foreach my $c1(sort keys(%{$params})) {	# sort so that the key is always the same
		my $arg = $params->{$c1};
		if(ref($arg)) {
			# throw Error::Simple("$query: argument is not a string: " . ref($arg));
			$self->_fatal("count(): $query: argument is not a string: ", ref($arg));
		}
		if(!defined($arg)) {
			my @call_details = caller(0);
			# throw Error::Simple("$query: value for $c1 is not defined in call from " .
				# $call_details[2] . ' of ' . $call_details[1]);
			Carp::croak("$query: value for $c1 is not defined in call from ",
				$call_details[2], ' of ', $call_details[1]);
		}

		my $keyword;
		if($done_where) {
			$keyword = 'AND';
		} else {
			$keyword = 'WHERE';
			$done_where = 1;
		}
		if($arg =~ /[%_]/) {
			$query .= " $keyword $c1 LIKE ?";
		} else {
			$query .= " $keyword $c1 = ?";
		}
		push @query_args, $arg;
	}
	if(!$self->{no_entry}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}

	if(defined($query_args[0])) {
		$self->_debug("count $query: ", join(', ', @query_args));
	} else {
		$self->_debug("count $query");
	}

	my $key;
	my $c;
	if($c = $self->{cache}) {
		$key = ref($self) . '::' . $query;
		$key =~ s/COUNT\((.+?)\)/$1/;
		$key .= ' array';
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		if(my $rc = $c->get($key)) {
			# Unlikely
			$self->_debug('cache HIT');
			return scalar @{$rc};	# We stored a ref to the array
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare($query)) {
		$sth->execute(@query_args) ||
			# throw Error::Simple("$query: @query_args");
			croak("$query: @query_args");

		my $count = $sth->fetchrow_arrayref()->[0];

		$sth->finish();

		return $count;
	}
	$self->_warn("count failure on $query: @query_args");
	# throw Error::Simple("$query: @query_args");
	croak("$query: @query_args");
}

=head2	fetchrow_hashref

Returns a hash reference for a single row in a table.

It searches for the given arguments, searching IS NULL if the value is C<undef>

   my $res = $foo->fetchrow_hashref(entry => 'one');

Special argument: table: determines the table to read from if not the default,
which is worked out from the class name

When no_entry is not set allow just one argument to be given: the entry value.

=cut

sub fetchrow_hashref {
	my $self = shift;

	$self->_trace('Entering fetchrow_hashref');

	my $params;

	if(!$self->{'no_entry'}) {
		$params = Params::Get::get_params('entry', @_);
	} else {
		$params = Params::Get::get_params(undef, @_);
	}

	my $table = $self->_open_table($params);

	# ::diag($self->{'type'});
	if($self->{'data'} && (!$self->{'no_entry'}) && (scalar keys(%{$params}) == 1) && defined($params->{'entry'})) {
		$self->_debug('Fast return from slurped data');
		return $self->{'data'}->{$params->{'entry'}};
	}

	if($self->{'berkeley'}) {
		# print STDERR ">>>>>>>>>>>>\n";
		# ::diag(Data::Dumper->new([$self->{'berkeley'}])->Dump());
		if((!$self->{'no_entry'}) && (scalar keys(%{$params}) == 1) && defined($params->{'entry'})) {
			return { entry => $self->{'berkeley'}->{$params->{'entry'}} };
		}
		my $id = $self->{'id'};
		if($self->{'no_entry'} && (scalar keys(%{$params}) == 1) && defined($id) && defined($params->{$id})) {
			if(my $rc = $self->{'berkeley'}->{$params->{$id}}) {
				return { $params->{$id} => $rc }	# Return key->value as a hash pair
			}
			return;
		}
		Carp::croak(ref($self), ': fetchrow_hashref is meaningless on a NoSQL database');
	}

	my $query = 'SELECT * FROM ';
	if(my $t = delete $params->{'table'}) {
		$query .= $t;
	} else {
		$query .= $table;
	}
	my $done_where = 0;

	if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
		$query .= ' WHERE ' . $self->{'id'} . ' IS NOT NULL AND ' . $self->{'id'} . " NOT LIKE '#%'";
		$done_where = 1;
	}
	my @query_args;
	foreach my $c1(sort keys(%{$params})) {	# sort so that the key is always the same
		my $keyword;

		if($done_where) {
			$keyword = 'AND';
		} else {
			$keyword = 'WHERE';
			$done_where = 1;
		}
		if(my $arg = $params->{$c1}) {
			if(ref($arg)) {
				# throw Error::Simple("$query: argument is not a string: " . ref($arg));
				$self->_fatal("fetchrow_hash(): $query: argument is not a string: ", ref($arg));
			}

			if($arg =~ /[%_]/) {
				$query .= " $keyword $c1 LIKE ?";
			} else {
				$query .= " $keyword $c1 = ?";
			}
			push @query_args, $arg;
		} else {
			$query .= " $keyword $c1 IS NULL";
			# my @call_details = caller(0);
			# # throw Error::Simple("$query: value for $c1 is not defined in call from " .
				# # $call_details[2] . ' of ' . $call_details[1]);
			# Carp::croak("$query: value for $c1 is not defined in call from ",
				# $call_details[2], ' of ', $call_details[1]);
		}
	}
	# $query .= ' ORDER BY entry LIMIT 1';
	$query .= ' LIMIT 1';
	if(defined($query_args[0])) {
		my @call_details = caller(0);
		$self->_debug("fetchrow_hashref $query: ", join(', ', @query_args),
			' called from ', $call_details[2], ' of ', $call_details[1]);
	} else {
		$self->_debug("fetchrow_hashref $query");
	}
	my $key = ref($self) . '::';
	if(defined($query_args[0])) {
		if(wantarray) {
			$key .= 'array ';
		}
		$key .= "fetchrow $query " . join(', ', @query_args);
	} else {
		$key .= "fetchrow $query";
	}
	my $c;
	if($c = $self->{cache}) {
		if(my $rc = $c->get($key)) {
			if(wantarray) {
				if(ref($rc) eq 'ARRAY') {
					return @{$rc};	# We stored a ref to the array
				}
			} else {
				return $rc;
			}
		}
	}

	my $sth = $self->{$table}->prepare($query) or die $self->{$table}->errstr();
	# $sth->execute(@query_args) || throw Error::Simple("$query: @query_args");
	$sth->execute(@query_args) || croak("$query: @query_args");
	my $rc = $sth->fetchrow_hashref();
	if($c) {
		if($rc) {
			$self->_debug("stash $key=>$rc in the cache for ", $self->{'cache_duration'});
			$self->_debug("returns ", Data::Dumper->new([$rc])->Dump());
		} else {
			$self->_debug("Stash $key=>undef in the cache for ", $self->{'cache_duration'});
		}
		$c->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

=head2	execute

Execute the given SQL query on the database.
In an array context, returns an array of hash refs,
in a scalar context returns a hash of the first row

On CSV tables without no_entry, it may help to add
"WHERE entry IS NOT NULL AND entry NOT LIKE '#%'"
to the query.

If the data have been slurped,
this will still work by accessing that actual database.

=cut

sub execute
{
	my $self = shift;

	if($self->{'berkeley'}) {
		Carp::croak(ref($self), ': execute is meaningless on a NoSQL database');
	}

	my $args = Params::Get::get_params('query', @_);
	# Ensure the 'query' parameter is provided
	Carp::croak(__PACKAGE__, ': Usage: execute(query => $query)')
		unless defined $args->{'query'};

	my $table = $self->_open_table($args);

	my $query = $args->{'query'};

	# Append "FROM <table>" if missing
	$query .= " FROM $table" unless $query =~ /\sFROM\s/i;

	# Log the query if a logger is available
	$self->_debug("execute $query");

	# Prepare and execute the query
	my $sth = $self->{$table}->prepare($query);
	$sth->execute() or croak($query);	# Die with the query in case of error

	# Fetch the results
	my @results;
	while (my $row = $sth->fetchrow_hashref()) {
		# Return a single hashref if scalar context is expected
		return $row unless wantarray;
		push @results, $row;
	}

	# Return all rows as an array in list context
	return @results;
}

=head2 updated

Returns the timestamp of the last database update.

=cut

sub updated {
	my $self = shift;

	return $self->{'_updated'};
}

=head2 AUTOLOAD

Directly access a database column.

Returns all entries in a column, a single entry based on criteria.
Uses cached data if available.

Returns an array of the matches,
or only the first when called in scalar context

If the database has a column called "entry" you can do a quick lookup with

    my $value = $foo->column('123');	# where "column" is the value you're after

    my @entries = $foo->entry();
    print 'There are ', scalar(@entries), " entries in the database\n";

Set distinct or unique to 1 if you're after a unique list.

Throws an error in slurp mode when an invalid column name is given.

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my ($column) = $AUTOLOAD =~ /::(\w+)$/;

	return if($column eq 'DESTROY');

	my $self = shift or return;

	Carp::croak(__PACKAGE__, ": Unknown column $column") if(!ref($self));

	# Allow the AUTOLOAD feature to be disabled
	Carp::croak(__PACKAGE__, ": Unknown column $column") if(exists($self->{'auto_load'}) && boolean($self->{'auto_load'})->isFalse());

	# Validate column name - only allow safe column name
	Carp::croak(__PACKAGE__, ": Invalid column name: $column") unless $column =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;

	my $table = $self->_open_table();

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif((scalar(@_) % 2) == 0) {
		%params = @_;
	} elsif(scalar(@_) == 1) {
		# Don't error on key-value databases, since there's no idea of columns
		if($self->{'no_entry'} && !$self->{'berkeley'}) {
			Carp::croak(ref($self), "::($_[0]): ", $self->{'id'}, ' is not a column');
		}
		$params{'entry'} = shift;
	}

	if($self->{'berkeley'}) {
		if(my $id = $self->{'id'}) {
			return $self->{'berkeley'}->{$params{$id}};
		}
		return $self->{'berkeley'}->{$params{'entry'}};
	}

	croak('Where did the data come from?') if(!defined($self->{'type'}));
	my $query;
	my $done_where = 0;
	my $distinct = delete($params{'distinct'}) || delete($params{'unique'});

	if(wantarray && !$distinct) {
		if(((scalar keys %params) == 0) && (my $data = $self->{'data'})) {
			# Return all the entries in the column
			return map { $_->{$column} } values %{$data};
		}
		if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
			$query = "SELECT $column FROM $table WHERE " . $self->{'id'} . " IS NOT NULL AND entry NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT $column FROM $table";
		}
	} else {
		if(my $data = $self->{'data'}) {
			# The data has been read in using Text::xSV::Slurp,
			#	so no need to do any SQL
			$self->_debug('AUTOLOAD using slurped data');
			if($self->{'no_entry'}) {
				$self->_debug('no_entry is set');
				my ($key, $value) = %params;
				if(defined($key)) {
					$self->_debug("key = $key, value = $value, column = $column");
					foreach my $row(@{$data}) {
						if(defined($row->{$key}) && ($row->{$key} eq $value) && (my $rc = $row->{$column})) {
							if(defined($rc)) {
								$self->_trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
							} else {
								$self->_trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
							}
							return $rc
						}
					}
					$self->_debug('not found in slurped data');
				}
			} elsif(((scalar keys %params) == 1) && defined(my $key = $params{'entry'})) {
				# Look up the key

				# This weird code is to stop the data hash becoming polluted with empty
				#	values as we look things up
				# my $rc = $data->{$key}->{$column};
				my $rc;
				if(defined(my $hash = $data->{$key})) {
					# Look up the key
					if(!exists($hash->{$column})) {
						Carp::croak(__PACKAGE__, ": There is no column $column in $table");
					}
					$rc = $hash->{$column};
				}
				if(defined($rc)) {
					$self->_trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
				} else {
					$self->_trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
				}
				return $rc
			} elsif((scalar keys %params) == 0) {
				if(wantarray) {
					if($distinct) {
						# https://stackoverflow.com/questions/7651/how-do-i-remove-duplicate-items-from-an-array-in-perl
						my %h = map { $_, 1 } map { $_->{$column} } values %{$data};
						return keys %h;
					}
					return map { $_->{$column} } values %{$data}
				}
				# FIXME - this works but really isn't the right way to do it
				foreach my $v (values %{$data}) {
					return $v->{$column}
				}
			} else {
				# It's keyed, but we're not querying off it
				my ($key, $value) = %params;
				foreach my $row (values %{$data}) {
					if(defined($row->{$key}) && ($row->{$key} eq $value) && (my $rc = $row->{$column})) {
						if(defined($rc)) {
							$self->_trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
						} else {
							$self->_trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
						}
						return $rc
					}
				}
			}
			return
		}
		# Data has not been slurped in
		if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
			$query = "SELECT DISTINCT $column FROM $table WHERE " . $self->{'id'} . " IS NOT NULL AND entry NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT DISTINCT $column FROM $table";
		}
	}
	my @args;
	while(my ($key, $value) = each %params) {
		$self->_debug(__PACKAGE__, ": AUTOLOAD adding key/value pair $key=>$value");
		if(defined($value)) {
			if($done_where) {
				$query .= " AND $key = ?";
			} else {
				$query .= " WHERE $key = ?";
				$done_where = 1;
			}
			push @args, $value;
		} else {
			$self->_debug("AUTOLOAD params $key isn't defined");
			if($done_where) {
				$query .= " AND $key IS NULL";
			} else {
				$query .= " WHERE $key IS NULL";
				$done_where = 1;
			}
		}
	}
	if(wantarray) {
		$query .= " ORDER BY $column";
	} else {
		$query .= ' LIMIT 1';
	}
	if(scalar(@args) && $args[0]) {
		$self->_debug("AUTOLOAD $query: ", join(', ', @args));
	} else {
		$self->_debug("AUTOLOAD $query");
	}
	my $cache;
	my $key = ref($self) . '::';
	if($cache = $self->{cache}) {
		if(wantarray) {
			$key .= 'array ';
		}
		if(defined($args[0])) {
			$key .= "fetchrow $query " . join(', ', @args);
		} else {
			$key .= "fetchrow $query";
		}
		if(my $rc = $cache->get($key)) {
			$self->_debug('cache HIT');
			return wantarray ? @{$rc} : $rc;	# We stored a ref to the array
		}
		$self->_debug('cache MISS');
	} else {
		$self->_debug('cache not used');
	}
	# my $sth = $self->{$table}->prepare($query) || throw Error::Simple($query);
	my $sth = $self->{$table}->prepare($query) || croak($query);
	# $sth->execute(@args) || throw Error::Simple($query);
	$sth->execute(@args) || croak($query);

	if(wantarray) {
		my @rc = map { $_->[0] } @{$sth->fetchall_arrayref()};
		if($cache) {
			$cache->set($key, \@rc, $self->{'cache_duration'});	# Store a ref to the array
		}
		Data::Reuse::fixate(@rc) if(!$self->{'no_fixate'});
		return @rc;
	}
	my $rc = $sth->fetchrow_array();	# Return the first match only
	$sth->finish();
	if($cache) {
		return $cache->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

sub DESTROY
{
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	# Clean up temporary file
	if($self->{'temp'}) {
		unlink delete $self->{'temp'};
	}

	# Clean up database handles
	my $table_name = $self->{'table'} || ref($self);
	$table_name =~ s/.*:://;

	if(my $dbh = delete $self->{$table_name}) {
		$dbh->disconnect() if $dbh->can('disconnect');
		$dbh->finish() if $dbh->can('finish');
	}

	# Clean up Berkeley DB
	if($self->{'berkeley'}) {
		eval {
			untie %{$self->{'berkeley'}};
		};
		delete $self->{'berkeley'};
	}

	# Clear all other attributes to break potential circular references
	foreach my $key (keys %$self) {
		delete $self->{$key};
	}
}

# Determine the table and open the database
sub _open_table
{
	my($self, $params) = @_;

	# Get table name (remove package name prefix if present)
	my $table = $params->{'table'} || $self->{'table'} || ref($self);
	$table =~ s/.*:://;

	# Open a connection if it's not already open
	$self->_open() if((!$self->{$table}) && (!$self->{'data'}));

	return $table;
}

# Determine whether a given file is a valid Berkeley DB file.
# It combines a fast preliminary check with a more thorough validation step for accuracy.
# It looks for the magic number at both byte 0 and byte 12
# TODO: Combine _db_0 and _db_12 as they are very similar routines
sub _is_berkeley_db {
	my ($self, $file) = @_;

	# Step 1: Check magic number
	open my $fh, '<', $file or return 0;
	binmode $fh;

	my $is_db = (($self->_is_berkeley_db_0($fh)) || ($self->_is_berkeley_db_12($fh)));
	close $fh;

	if($is_db) {
		# Step 2: Attempt to open as Berkeley DB

		require DB_File && DB_File->import();

		my %bdb;
		if(tie %bdb, 'DB_File', $file, O_RDONLY, 0644, $DB_File::DB_HASH) {
			# untie %db;
			$self->{'berkeley'} = \%bdb;
			return 1;	# Successfully identified as a Berkeley DB file
		}
	}
	return 0;
}

# Determine whether a given file is a valid Berkeley DB file.
# It combines a fast preliminary check with a more thorough validation step for accuracy.
sub _is_berkeley_db_0
{
	my ($self, $fh) = @_;

	# Read the first 4 bytes (magic number)
	read($fh, my $magic_bytes, 4) == 4 or return 0;

	# Unpack both big-endian and little-endian values
	my $magic_be = unpack('N', $magic_bytes);	# Big-endian
	my $magic_le = unpack('V', $magic_bytes);	# Little-endian

	# Known Berkeley DB magic numbers (in both endian formats)
	my %known_magic = map { $_ => 1 } (
		0x00061561,	# Btree
		0x00053162,	# Hash
		0x00042253,	# Queue
		0x00052444,	# Recno
	);

	return($known_magic{$magic_be} || $known_magic{$magic_le});
}

sub _is_berkeley_db_12
{
	my ($self, $fh) = @_;
	my $header;

	seek $fh, 12, 0 or return 0;
	read($fh, $header, 4) or return 0;

	$header = substr(unpack('H*', $header), 0, 4);

	# Berkeley DB magic numbers
	return($header eq '6115' || $header eq '1561');	# Btree
}

# Log and remember a message
sub _log
{
	my ($self, $level, @messages) = @_;

	# FIXME: add caller's function
	# if(($level eq 'warn') || ($level eq 'notice')) {
		push @{$self->{'messages'}}, { level => $level, message => join('', grep defined, @messages) };
	# }

	if(scalar(@messages) && (my $logger = $self->{'logger'})) {
		$self->{'logger'}->$level(join('', grep defined, @messages));
	}
}

sub _debug {
	my $self = shift;
	$self->_log('debug', @_);
}

sub _trace {
	my $self = shift;
	$self->_log('trace', @_);
}

# Emit a warning message somewhere
sub _warn {
	my $self = shift;
	my $params = Params::Get::get_params('warning', @_);

	$self->_log('warn', $params->{'warning'});
	Carp::carp(join('', grep defined, $params->{'warning'}));
}

# Die
sub _fatal {
	my $self = shift;
	my $params = Params::Get::get_params('warning', @_);

	$self->_log('error', $params->{'warning'});
	Carp::croak(join('', grep defined, $params->{'warning'}));
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-database-abstraction at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 BUGS

The default delimiter for CSV files is set to '!', not ',' for historical reasons.
I really ought to fix that.

It would be nice for the key column to be called key, not entry,
however key's a reserved word in SQL.

The no_entry parameter should be no_id.

XML slurping is hard,
so if XML fails for you on a small file force non-slurping mode with

    $foo = MyPackageName::Database::Foo->new({
	directory => '/var/dat',
	max_slurp_size => 0	# force to not use slurp and therefore to use SQL
    });

=head1 SEE ALSO

=over 4

=item * Test coverage report: L<https://nigelhorne.github.io/Database-Abstraction/coverage/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2025 Nigel Horne.

This program is released under the following licence: GPL2.
Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (for example, Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.

=cut

1;
