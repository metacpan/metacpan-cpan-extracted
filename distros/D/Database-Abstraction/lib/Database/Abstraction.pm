package Database::Abstraction;

# Author Nigel Horne: njh@nigelhorne.com
# Copyright (C) 2015-2026, Nigel Horne

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
# TODO:	Other databases e.g., Redis, noSQL, remote databases such as MySQL, PostgreSQL
# TODO: The no_entry/entry terminology is confusing.  Replace with no_id/id_column
# TODO: Add support for DBM::Deep
# TODO: Log queries and the time that they took to execute per database

use warnings;
use strict;
use autodie qw(:all);

use boolean;
use Carp;
use Class::Abstract;
use Data::Reuse;
use DBI;
use Fcntl;	# For O_RDONLY
use Cwd;
use File::Spec;
use File::Temp;
use List::Util qw(all);
use Log::Abstraction 0.26;
use Object::Configure 0.16;
use Params::Get 0.13;
use Return::Set qw(set_return);
use Scalar::Util;

our %defaults;
use constant	DEFAULT_MAX_SLURP_SIZE => 16 * 1024;	# CSV files <= than this size are read into memory

=head1 NAME

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

=head1 VERSION

Version 0.36

=cut

our $VERSION = '0.36';

=head1 DESCRIPTION

C<Database::Abstraction> is a read-only ORM for Perl that gives a uniform
interface over CSV, PSV, XML, SQLite, and BerkeleyDB files - without writing
any SQL.

Key features:

=over 4

=item *

B<No SQL required.>  Use plain Perl method calls for simple lookups and
scans; switch storage formats without changing application code.

=item *

B<Rich query criteria.>  Pass plain values, SQL wildcards, C<undef> (IS NULL),
comparison operators (C<< > >> C<< < >> C<< >= >> C<< <= >> C<!=>), pattern
operators (C<-like>, C<-not_like>), set operators (C<-in>, C<-not_in>,
C<-between>), and logical groupings (C<-or>, C<-and>).

=item *

B<Automatic joins.>  Add a C<join> parameter to any select method to
combine tables with INNER, LEFT, RIGHT, FULL, or CROSS joins.

=item *

B<Chained query builder.>  The C<query()> method returns a
L<Database::Abstraction::Query> object for fluent, composable queries:
C<< $db->query->where(...)->order_by(...)->limit(...)->all() >>.

=item *

B<Schema introspection.>  C<columns()> lists column names; C<schema()>
returns full type/nullability metadata, using native driver introspection
(C<PRAGMA table_info> for SQLite, C<column_info> for others).

=item *

B<DSN portability.>  Pass a C<dsn> (plus optional C<username>/C<password>)
to connect to any DBI-supported database (SQLite, PostgreSQL, MySQL, ...)
instead of pointing at a local file.

=item *

B<Performance.>  Small files are slurped into a RAM hash for sub-millisecond
lookups.  All DBI statement handles are cached with C<prepare_cached()>.
A CHI-compatible cache layer is also supported.

=back

=head1 SYNOPSIS

    # 1. Create a thin subclass for your table (e.g. Database/Foo.pm)
    package Database::Foo;
    use parent 'Database::Abstraction';

    # 2. Open the database - file is auto-detected from the class name
    #    (looks for foo.sql / foo.psv / foo.csv / foo.xml / foo.db)
    my $db = Database::Foo->new(directory => '/path/to/data');

    # 3. Simple lookups -----------------------------------------------

    # Fetch one row
    my $row = $db->fetchrow_hashref(entry => 'key1');

    # Fetch all rows matching a criterion
    my $rows = $db->selectall_arrayref(status => 'active');

    # Column shortcut via AUTOLOAD
    my $name = $db->name(entry => 'key1');

    # 4. Rich criteria ------------------------------------------------

    # Comparison operators
    my $high = $db->selectall_arrayref(score => { '>' => 90 });

    # Set membership
    my $selected = $db->selectall_arrayref(
        name => { -in => ['Alice', 'Bob'] }
    );

    # Range
    my $mid = $db->selectall_arrayref(
        score => { -between => [60, 80] }
    );

    # OR grouping
    my $either = $db->selectall_arrayref(
        -or => [
            { status => 'active'    },
            { score  => { '>' => 95 } },
        ]
    );

    # 5. Joins --------------------------------------------------------

    my $joined = $db->selectall_arrayref(
        join => { table => 'dept', on => 'foo.dept_id = dept.id', type => 'LEFT' }
    );

    # 6. Chained query builder ----------------------------------------

    my $results = $db->query
        ->where(status => 'active')
        ->where(score  => { '>=' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->all();

    my $first = $db->query->where(name => 'Alice')->first();
    my $count = $db->query->where(status => 'active')->count();

    # 7. Connect via DSN (PostgreSQL, MySQL, SQLite, ...) ---------------

    my $db2 = Database::Foo->new(
        dsn      => 'dbi:Pg:dbname=mydb;host=db.example.com',
        username => 'myuser',
        password => 's3cret',
    );

    # 8. Schema introspection -----------------------------------------

    my $cols   = $db->columns();  # ['entry', 'name', 'score', ...]
    my $schema = $db->schema();   # { name => { type=>'TEXT', nullable=>1, ... }, ... }

=head1 QUICK START EXAMPLE

If F</var/dat/foo.csv> contains:

    "customer_id","name"
    "plugh","John"
    "xyzzy","Jane"

Create a driver in F<.../Database/foo.pm>:

    package Database::foo;
    use parent 'Database::Abstraction';

    # Regular CSV: no entry column, comma-separated
    sub new {
        my ($class, %args) = @_;
        return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

Then query it:

    my $foo = Database::foo->new(directory => '/var/dat');

    # Prints "John"
    print 'Customer: ', $foo->name(customer_id => 'plugh'), "\n";

    # Returns { customer_id => 'xyzzy', name => 'Jane' }
    my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');

=head1 FILE FORMATS

The module probes the C<directory> for files in this priority order:

=over 4

=item 1. C<SQLite>

File ending C<.sql>

=item 2. C<PSV>

Pipe-separated file, ending C<.psv>

=item 3. C<CSV>

Comma (or custom) separated file, ending C<.csv> or C<.db>; can be
gzipped.  B<Note:> the default separator is C<!> not C<,> for historical
reasons - pass C<< sep_char => ',' >> for standard CSVs.

=item 4. C<XML>

File ending C<.xml>

=item 5. C<BerkeleyDB>

Binary key-value file ending C<.db>

=back

Pass C<dsn> to bypass file detection entirely and connect via any DBI driver.

=head1 QUERY CRITERIA

All select methods (C<selectall_arrayref>, C<selectall_array>,
C<fetchrow_hashref>, C<count>) accept the same criteria syntax.

=head2 Plain value

    status => 'active'          # status = 'active'
    name   => undef             # name IS NULL

Values containing C<%> or C<_> are matched with C<LIKE>:

    name => 'A%'                # name LIKE 'A%'

=head2 Comparison operator hashref

    score => { '>'  => 90  }   # score > 90
    score => { '<'  => 50  }   # score < 50
    score => { '>=' => 80  }   # score >= 80
    score => { '<=' => 100 }   # score <= 100
    score => { '!=' => 0   }   # score != 0

Multiple operators on one column are ANDed:

    score => { '>' => 60, '<' => 90 }   # 60 < score < 90

=head2 Pattern matching

    name => { -like     => 'A%'  }   # name LIKE 'A%'
    name => { -not_like => 'Z%'  }   # name NOT LIKE 'Z%'

=head2 Set membership

    name => { -in     => ['Alice', 'Bob'] }   # name IN (...)
    name => { -not_in => ['Alice', 'Bob'] }   # name NOT IN (...)

=head2 Range

    score => { -between => [60, 90] }   # score BETWEEN 60 AND 90

=head2 Logical groupings

C<-or> and C<-and> take an arrayref of condition hashrefs:

    -or => [
        { status => 'active'        },
        { score  => { '>' => 95 }   },
    ]

    -and => [
        { status => 'active'        },
        { score  => { '>=' => 80 }  },
    ]

=head2 Joins

Any select method accepts a C<join> key with a hashref (or arrayref of
hashrefs) describing the join:

    join => {
        table => 'dept',
        on    => 'employees.dept_id = dept.id',
        type  => 'LEFT',    # INNER (default) | LEFT | RIGHT | FULL | CROSS
    }

    # Multiple joins
    join => [
        { table => 'dept',    on => 'e.dept_id   = dept.id'   },
        { table => 'country', on => 'e.country_id = country.id' },
    ]

=head1 SUBROUTINES/METHODS

=head2 init

Set class-level defaults shared by all instances.

    Database::Abstraction::init(directory => '../data');

Accepts the same parameters as L</new>.  Returns a reference to the
current defaults hash, so you can read them back:

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

Create an object pointing to a read-only database.

Accepts arguments as a hash, a hashref, or - as a shortcut - a single bare
string which is taken to be C<directory>.

=head3 Connection parameters

=over 4

=item * C<directory>

Directory containing the data files.  The module probes this directory for
files named after the subclass (see L</FILE FORMATS>).  Required unless
C<dsn> is given.

=item * C<dsn>

A DBI data-source string (e.g. C<dbi:SQLite:dbname=/path/to/db> or
C<dbi:Pg:dbname=mydb;host=db.example.com>).  When present, file detection
is skipped entirely and the DSN is used directly.  The SQL dialect is
inferred from the DSN prefix (C<sqlite>, C<postgres>, C<mysql>).

=item * C<username>

Database username.  Used only with C<dsn>; ignored for file-based backends.

=item * C<password>

Database password.  Used only with C<dsn>; ignored for file-based backends.

=item * C<dbname>

Override the filename stem searched in C<directory> (default: the table
name derived from the class name).

=item * C<filename>

Override the full filename (relative to C<directory>).  Takes precedence
over C<dbname>.

=back

=head3 Behaviour parameters

=over 4

=item * C<no_entry>

Set to C<1> when the table has no key column (standard CSVs, for example).
Default is C<0> (keyed on C<entry>).

=item * C<id>

Name of the key column.  Default is C<entry>.

=item * C<sep_char>

Field separator for CSV/PSV files.
Default is C<!> - pass C<< sep_char => ',' >>
for standard comma-separated files.

=item * C<max_slurp_size>

Files smaller than this (in bytes) are loaded entirely into memory for fast
lookups.  Default is 16 KB.  Set to C<0> to force SQL mode for all sizes.

=item * C<no_fixate>

Set to C<1> to return mutable arrays.  Default is C<0> (arrays are made
read-only via L<Data::Reuse>).

=item * C<auto_load>

Set to C<0> to disable the AUTOLOAD column shortcut.  Default is C<1>
(enabled).

=back

=head3 Caching and logging

=over 4

=item * C<cache>

A L<CHI>-compatible cache object.  When set, query results are stored and
retrieved from the cache.

=item * C<cache_duration> / C<expires_in>

TTL for cached results.  Default is C<'1 hour'>.  C<expires_in> is a
synonym for compatibility with L<CHI>.

=item * C<logger>

An object that understands C<warn()> and C<trace()> (e.g.
L<Log::Log4perl>, L<Log::Any>), a code reference, or a filename.

=item * C<config_file>

Path to a YAML, XML, or INI configuration file whose keys are merged into
the constructor arguments.  Loaded via L<Object::Configure>.

=back

=head3 Notes

=over 4

=item *

If no arguments are set, class-level defaults set via C<init()> or C<use>
are used.

=item *

Slurp mode assumes the key column (C<entry>) is unique.  If it is not,
searches will be incomplete - disable slurp mode by setting
C<< max_slurp_size => 0 >>.

=item *

Passing an existing object as C<$class> clones it, merging any new
arguments.

=back

=cut

sub new {
	my $class = shift;
	my %args;

	Class::Abstract::check_abstract($class);	# enforces abstract contract

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

	# Normalise logger: wrap code-refs, filenames, and strings in Log::Abstraction
	# so that the rest of the code can always call ->$level(...) uniformly.
	if(defined $args{'logger'} && !Scalar::Util::blessed($args{'logger'})) {
		$args{'logger'} = Log::Abstraction->new($args{'logger'});
	}

	unless($args{'dsn'} || $defaults{'dsn'}) {
		croak("$class: where are the files?") unless($args{'directory'} || $defaults{'directory'});

		croak("$class: ", $args{'directory'} || $defaults{'directory'}, ' is not a directory') unless(-d ($args{'directory'} || $defaults{'directory'}));
	}

	# Validate the primary-key column name to prevent SQL injection via ORDER BY / WHERE
	for my $src (\%defaults, \%args) {
		if(defined $src->{'id'}) {
			croak("$class: unsafe id column name '$src->{id}'")
				unless $src->{'id'} =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/;
		}
	}

	# Defaults are set first so that %args keys override them
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

	if(my $logger = $params->{'logger'}) {
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
	# Enforce that _open is only reachable from within this class hierarchy;
	# caller() returns the calling package name as a plain string.
	do { my $c = (caller)[0]; Carp::croak('Illegal Operation: _open may only be called within ', __PACKAGE__) unless $c && $c->isa(__PACKAGE__) };

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

	# DSN-based connection bypasses file detection entirely
	if(my $dsn = $self->{'dsn'} || $defaults{'dsn'}) {
		require DBI && DBI->import() unless DBI->can('connect');

		my $dialect = 'generic';
		if    ($dsn =~ /^dbi:SQLite:/i) { $dialect = 'sqlite'   }
		elsif ($dsn =~ /^dbi:Pg:/i)     { $dialect = 'postgres' }
		elsif ($dsn =~ /^dbi:mysql:/i)  { $dialect = 'mysql'    }
		$self->{'_dialect'} = $dialect;

		$dbh = DBI->connect(
			$dsn,
			$self->{'username'},
			$self->{'password'},
			{ RaiseError => 1, AutoCommit => 1 },
		) or Carp::croak(ref($self), ": cannot connect: $DBI::errstr");

		if($dialect eq 'sqlite') {
			$dbh->do('PRAGMA synchronous = OFF');
			$dbh->do('PRAGMA cache_size = -4096');
			$dbh->do('PRAGMA journal_mode = OFF');
			$dbh->do('PRAGMA temp_store = MEMORY');
			$dbh->do('PRAGMA mmap_size = 1048576');
			$dbh->sqlite_busy_timeout(100000);
		}

		$self->{'type'} = 'DBI';
		$self->{$table} = $dbh;
		$self->{'_updated'} = time();
		return $self;
	}

	my $dir = Cwd::abs_path($self->{'directory'} || $defaults{'directory'});
	my $dbname = $self->{'dbname'} || $defaults{'dbname'} || $table;
	Carp::croak(ref($self), ": unsafe dbname '$dbname'")
		unless $dbname =~ /^[a-zA-Z0-9_.-]+$/ && $dbname !~ /\.\./;
	my $slurp_file = File::Spec->catfile($dir, "$dbname.sql");

	$self->_debug("_open: try to open $slurp_file");

	# Look at various places to find the file and derive the file type from the file's name
	if(-r $slurp_file) {
		# SQLite file
		require DBI && DBI->import() unless DBI->can('connect');

		require DBD::SQLite::Constants;
		$dbh = DBI->connect("dbi:SQLite:dbname=$slurp_file", undef, undef, {
			sqlite_open_flags => DBD::SQLite::Constants::SQLITE_OPEN_READONLY(),
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
		# File::pfopen splits $path on ':' which breaks Windows drive letters
		# (C:\foo becomes ['C', '\foo']).  Since we always have a single directory
		# we use File::Spec->catfile directly — same behaviour, portable.
		for my $ext (qw(csv.gz db.gz)) {
			my $candidate = File::Spec->catfile($dir, "$dbname.$ext");
			next unless -r $candidate;
			open($fin, '<', $candidate) or next;
			$slurp_file = $candidate;
			last;
		}
		if(defined($slurp_file) && (-r $slurp_file)) {
			require Gzip::Faster;
			Gzip::Faster->import();

			close($fin);
			$fin = File::Temp->new(SUFFIX => '.csv', UNLINK => 1);
			print $fin gunzip_file($slurp_file);
			$fin->flush();
			$slurp_file = $fin->filename();
			$self->{'_temp_fh'} = $fin;	# Keep object alive; auto-unlinks at DESTROY
		} else {
			my $psv = File::Spec->catfile($dir, "$dbname.psv");
			if(-r $psv && open($fin, '<', $psv)) {
				# Pipe separated file
				$slurp_file = $psv;
				$params->{'sep_char'} = '|';
			} else {
				# CSV or BerkeleyDB-extension file
				for my $ext (qw(csv db)) {
					my $candidate = File::Spec->catfile($dir, "$dbname.$ext");
					next unless -r $candidate;
					open($fin, '<', $candidate) or next;
					$slurp_file = $candidate;
					last;
				}
			}
		}
		if(my $filename = $self->{'filename'} || $defaults{'filename'}) {
			Carp::croak(ref($self), ": unsafe filename '$filename'")
				unless $filename =~ /^[a-zA-Z0-9_.-]+$/ && $filename !~ /\.\./;
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
						f_dir      => $dir,
						RaiseError => 1,
						PrintError => 0
					}
				);
			} else {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef, { csv_sep_char => $sep_char, f_dir => $dir, RaiseError => 1 });
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

			# Text::xSV::Slurp cannot override column names, so skip slurp when
			# column_names is set — the DBI CSV connection will supply names instead.
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

					# Filter out blank lines and comment rows (lines starting with #)
					my @data = grep { $_->{$self->{'id'}} !~ /^\s*#/ } grep { defined($_->{$self->{'id'}}) } @{$dataref};

					if($self->{'no_entry'}) {
						# Not keyed on a primary column — keep as ordered list.
						# Only store a reference when rows were found; an empty-array ref
						# is truthy, which would activate the in-memory fast-path and
						# silently return 0 results instead of falling through to SQL.
						$self->{'data'} = @data ? \@data : undef;
					} else {
						# Key the hash by $self->{'id'} for O(1) entry lookups
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
								Carp::croak('XML slurp: complex documents with an "entry" field are not yet supported');
							}
						} else {
							Carp::croak('XML slurp: multi-key documents are not yet supported');
						}
					} else {
						Carp::croak('XML slurp: cannot handle ', ref($xml), ' structure');
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

	# ref() must be called on the variable, not on the result of 'eq'
	Data::Reuse::fixate(%{$self->{'data'}}) if($self->{'data'} && (ref($self->{'data'}) eq 'HASH'));

	$self->{$table} = $dbh;
	my @statb = stat($slurp_file);
	$self->{'_updated'} = $statb[9];

	return $self;
}

=head2 selectall_arrayref

Returns a reference to an array of hash references for every row that
matches the given criteria, or C<undef> when there are no matches.

    my $rows = $db->selectall_arrayref();                    # all rows
    my $rows = $db->selectall_arrayref(status => 'active');  # exact match
    my $rows = $db->selectall_arrayref(score => { '>' => 8 });  # operator

The full criteria syntax is described in L</QUERY CRITERIA>.

Pass a C<join> key to combine with another table:

    my $rows = $db->selectall_arrayref(
        dept_name => 'Engineering',
        join      => { table => 'dept', on => 'e.dept_id = dept.id' },
    );

Results are returned in the cache (if configured) and the returned array
reference is made read-only unless C<no_fixate> was set.

B<Note:> this always returns all matching rows.  Use L</selectall_array>
in scalar context, or C<< $db->query->limit(1)->all() >>, to fetch just one row.

=head3 PSEUDOCODE

    1. Parse criteria; extract and build any JOIN clause.
    2. If data is slurped AND no joins AND criteria are simple:
       a. No criteria -> return all rows as arrayref.
       b. entry-only lookup -> return [$data{entry}].
       c. Otherwise -> scan rows in-memory with _match_criterion.
    3. Otherwise build SQL: SELECT * FROM table [JOIN] [WHERE] ORDER BY id.
    4. Check cache; return cached arrayref on HIT.
    5. prepare_cached + execute; fetch all rows.
    6. Store result in cache; fixate the array; return arrayref.

=cut

sub selectall_arrayref {
	my $self = shift;

	# Fire _open() first so $self->{'berkeley'} is known before we parse @_.
	# BerkeleyDB param parsing must use get_params(undef, \@_) so that
	# key-value pairs like (join => {...}) are not mangled by the positional
	# 'entry' mapping that non-BerkeleyDB paths use.
	$self->_open_table({});

	my $params;

	if($self->{'berkeley'}) {
		$params = Params::Get::get_params(undef, \@_) // {};
		return set_return($self->_scan_berkeley($params), { type => 'arrayref' });
	}

	if($self->{'no_entry'}) {
		$params = Params::Get::get_params(undef, \@_);
	} elsif(scalar(@_)) {
		$params = Params::Get::get_params('entry', @_);
	}

	my $table = $self->_open_table($params);

	$params //= {};

	my $join_clause = '';
	if(my $join_spec = delete $params->{'join'}) {
		$join_clause = $self->_build_joins($join_spec);
	}

	if(!$join_clause && $self->{'data'} && !$self->_has_complex_criteria($params)) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: selectall_arrayref fast track return");
			if(ref($self->{'data'}) eq 'HASH') {
				$self->_debug("$table: returning ", scalar keys %{$self->{'data'}}, ' entries');
				if(scalar keys %{$self->{'data'}} <= 10) {
					$self->_debug(do { require Data::Dumper; Data::Dumper::Dumper($self->{'data'}) });
				}
				my @rc = values %{$self->{'data'}};
				return set_return(\@rc, { type => 'arrayref' });
			}
			return set_return($self->{'data'}, { type => 'arrayref'});
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			# exists() guard: fixate() locks all keys in the slurp hash; return []
			# (not [undef]) when the key is missing so callers get an empty result
			return set_return([], { type => 'arrayref' })
				unless exists($self->{'data'}->{$params->{'entry'}});
			return set_return([$self->{'data'}->{$params->{'entry'}}], { type => 'arrayref' });
		} elsif(ref($self->{'data'}) eq 'HASH') {
			# Scan in-memory hash for simple column criteria without touching DBI.
			# fixate() locks hash keys, so use exists() to avoid throwing on unknown columns.
			$self->_debug("$table: selectall_arrayref in-memory scan with criteria");
			my @rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}) } keys %{$params}
			} values %{$self->{'data'}};
			return set_return(\@rc, { type => 'arrayref' });
		}
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $table";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
	if(!$self->{'no_entry'}) {
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
		$self->_debug("cache key = '$key'");
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

	if(my $sth = $self->{$table}->prepare_cached($query)) {
		$sth->execute(@query_args) || croak("$query: @query_args");

		my $rc;
		while(my $href = $sth->fetchrow_hashref()) {
			push @{$rc}, $href if(scalar keys %{$href});
		}
		$c->set($key, $rc, $self->{'cache_duration'}) if $c;

		if(!$self->{'no_fixate'}) {
			# forget() clears stale address→canonical mappings from prior calls;
			# fixate() then deduplicates values within this result set only.
			# Without forget(), freed hashref addresses from previous fixate calls
			# can collide with new DBI hashrefs and return wrong canonical rows.
			Data::Reuse::forget();
			Data::Reuse::fixate(@{$rc});
		}

		return $rc;
	}
	$self->_warn("selectall_arrayref failure on $query: @query_args");
	croak("$query: @query_args");
}

=head2 selectall_hashref

Deprecated alias for L</selectall_arrayref>.  Use C<selectall_arrayref> in
new code.

=cut

sub selectall_hashref
{
	my $self = shift;
	return $self->selectall_arrayref(@_);
}

=head2 selectall_array

Similar to L</selectall_arrayref> but returns a list of hash references
rather than a reference to an array.

    my @rows = $db->selectall_array(status => 'active');

In B<scalar context> it applies C<LIMIT 1> and returns just the first
matching hash reference - making it more efficient than C<selectall_arrayref>
when you only need one row.  In B<list context> all matching rows are returned.

Accepts the same criteria and C<join> parameter as L</selectall_arrayref>.

=cut

sub selectall_array
{
	my $self = shift;

	$self->_open_table({});

	if($self->{'berkeley'}) {
		my $params = Params::Get::get_params(undef, \@_) // {};
		my $rows = $self->_scan_berkeley($params);
		return wantarray ? @{$rows} : $rows->[0];
	}

	my $params = Params::Get::get_params(undef, \@_);
	my $table = $self->_open_table($params);

	$params //= {};
	my $join_clause = '';
	if(my $join_spec = delete $params->{'join'}) {
		$join_clause = $self->_build_joins($join_spec);
	}

	if(!$join_clause && $self->{'data'} && !$self->_has_complex_criteria($params)) {
		if(scalar(keys %{$params}) == 0) {
			$self->_trace("$table: selectall_array fast track return");
			if(ref($self->{'data'}) eq 'HASH') {
				return values %{$self->{'data'}};
			}
			return @{$self->{'data'}};
		} elsif((scalar(keys %{$params}) == 1) && defined($params->{'entry'}) && !$self->{'no_entry'}) {
			# exists() guard: fixate() locks all keys; return empty list (not undef)
			# for a missing entry so callers in list context get 0 elements not 1
			return () unless exists($self->{'data'}->{$params->{'entry'}});
			return $self->{'data'}->{$params->{'entry'}};
		} elsif(ref($self->{'data'}) eq 'HASH') {
			# Same as selectall_arrayref scan but returns a list
			$self->_debug("$table: selectall_array in-memory scan with criteria");
			my @rc = grep {
				my $row = $_;
				all { $self->_match_criterion(exists($row->{$_}) ? $row->{$_} : undef, $params->{$_}) } keys %{$params}
			} values %{$self->{'data'}};
			return @rc;
		}
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $table";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
	if(!$self->{'no_entry'}) {
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
		$self->_debug("cache key = '$key'");
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

	if(my $sth = $self->{$table}->prepare_cached($query)) {
		$sth->execute(@query_args) || croak("$query: @query_args");

		my $rc;
		while(my $href = $sth->fetchrow_hashref()) {
			if(!wantarray) {
				# Scalar context: return just the first row; cache it too
				$sth->finish();
				$c->set($key, [$href], $self->{'cache_duration'}) if $c;
				return $href;
			}
			push @{$rc}, $href;
		}
		$c->set($key, $rc, $self->{'cache_duration'}) if $c;

		if($rc) {
			if(!$self->{'no_fixate'}) {
				Data::Reuse::forget();
				Data::Reuse::fixate(@{$rc});
			}
			return @{$rc};
		}
		return;
	}
	$self->_warn("selectall_array failure on $query: @query_args");
	croak("$query: @query_args");
}

=head2 selectall_hash

Deprecated alias for L</selectall_array>.  Use C<selectall_array> in new
code.

=cut

sub selectall_hash
{
	my $self = shift;
	return $self->selectall_array(@_);
}

=head2 count

Returns the number of rows matching the given criteria.

    my $total  = $db->count();
    my $active = $db->count(status => 'active');
    my $high   = $db->count(score  => { '>' => 90 });

Accepts the full criteria syntax described in L</QUERY CRITERIA>.

=cut

sub count
{
	my $self = shift;

	$self->_open_table({});

	if($self->{'berkeley'}) {
		my $params = Params::Get::get_params(undef, \@_) // {};
		return scalar @{$self->_scan_berkeley($params)};
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
			# exists() guard: fixate() locks all keys in the slurp hash
			return (exists($self->{'data'}->{$params->{'entry'}}) && $self->{'data'}->{$params->{'entry'}}) ? 1 : 0;
		}
	}

	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query;
	if(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query = "SELECT COUNT(*) FROM $table WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} elsif($self->{'no_entry'}) {
		$query = "SELECT COUNT(*) FROM $table";
		$query .= " WHERE $where" if $where;
	} else {
		$query = "SELECT COUNT(" . $self->{'id'} . ") FROM $table";
		$query .= " WHERE $where" if $where;
	}

	if(defined($query_args[0])) {
		$self->_debug("count $query: ", join(', ', @query_args));
	} else {
		$self->_debug("count $query");
	}

	my $key;
	my $c;
	if($c = $self->{'cache'}) {
		# Opportunistic: if a selectall_arrayref for the same criteria is already
		# in cache, derive the count from that array rather than hitting the DB.
		# The key is built to match what selectall_arrayref would store.
		$key = ref($self) . '::' . $query;
		$key =~ s/COUNT\((.+?)\)/$1/;
		$key .= ' array';
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		if(my $rc = $c->get($key)) {
			$self->_debug('count: cache HIT (selectall array)');
			return ref($rc) eq 'ARRAY' ? scalar @{$rc} : 0;
		}
		$self->_debug('count: cache MISS');
	} else {
		$self->_debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare_cached($query)) {
		$sth->execute(@query_args) || croak("$query: @query_args");

		my $count = $sth->fetchrow_arrayref()->[0];
		$sth->finish();

		return $count;
	}
	$self->_warn("count failure on $query: @query_args");
	croak("$query: @query_args");
}

=head2 fetchrow_hashref

Returns a hash reference for the first row matching the given criteria,
or C<undef> when there is no match.  Always applies C<LIMIT 1>.

    my $row = $db->fetchrow_hashref(entry => 'key1');
    my $row = $db->fetchrow_hashref(score => { '>=' => 10 });

When C<no_entry> is B<not> set you may pass a single bare value and it is
used as the C<entry> key:

    my $row = $db->fetchrow_hashref('key1');    # same as entry => 'key1'

Accepts the full criteria syntax described in L</QUERY CRITERIA>, including
the C<join> parameter:

    my $row = $db->fetchrow_hashref(
        name => 'Alice',
        join => { table => 'dept', on => 'e.dept_id = dept.id' },
    );

Pass C<< table => $other_table >> to query a table other than the one
derived from the class name.

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
	if($self->{'data'} && (!$self->{'no_entry'}) && (scalar keys(%{$params}) == 1) && defined($params->{'entry'}) && !$self->_has_complex_criteria($params)) {
		$self->_debug('Fast return from slurped data');
		# Use exists() — fixate() locks the outer hash; accessing a missing key throws
		return exists($self->{'data'}->{$params->{'entry'}}) ? $self->{'data'}->{$params->{'entry'}} : undef;
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

	my $target = delete($params->{'table'}) // $table;
	my $join_spec = delete $params->{'join'};
	my $join_clause = $join_spec ? $self->_build_joins($join_spec) : '';
	my ($where, $wargs) = $self->_build_where($params);
	my @query_args = @{$wargs};

	my $query = "SELECT * FROM $target";
	$query .= " $join_clause" if $join_clause;
	if($join_clause) {
		$query .= " WHERE $where" if $where;
	} elsif(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
		my $id = $self->{'id'};
		$query .= " WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
		$query .= " AND ($where)" if $where;
	} else {
		$query .= " WHERE $where" if $where;
	}
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

	my $sth = $self->{$table}->prepare_cached($query)
		or Carp::croak(ref($self), ": prepare failed: ", $self->{$table}->errstr());
	$sth->execute(@query_args) || croak("$query: @query_args");
	my $rc = $sth->fetchrow_hashref();
	$sth->finish();
	if($c) {
		if($rc) {
			$self->_debug("stash $key=>$rc in the cache for ", $self->{'cache_duration'});
			$self->_debug("returns ", do { require Data::Dumper; Data::Dumper->new([$rc])->Dump() });
		} else {
			$self->_debug("Stash $key=>undef in the cache for ", $self->{'cache_duration'});
		}
		$c->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

=head2 execute

Execute a raw SQL query on the underlying database.

    # Scalar context: returns the first row as a hashref
    my $row = $db->execute(query => 'SELECT * FROM foo WHERE id = 1');

    # List context: returns all rows as a list of hashrefs
    my @rows = $db->execute(query => 'SELECT * FROM foo WHERE score > ?',
                            args  => [80]);

The C<FROM E<lt>tableE<gt>> clause is appended automatically if omitted.

On CSV tables without C<no_entry> it may help to add
C<WHERE entry IS NOT NULL AND entry NOT LIKE '#%'> to filter comment rows.

If the data have been slurped into memory this method still hits the actual
database file directly.

C<args> is an arrayref of bind values (see L<DBI/execute>).

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
	my $sth = $self->{$table}->prepare_cached($query);
	# DBI->execute() takes a list; normalise args to an array whether it
	# was passed as an arrayref ([30]) or a bare scalar/list (30).
	if(exists($args->{'args'})) {
		my @bind = ref($args->{'args'}) eq 'ARRAY' ? @{$args->{'args'}} : ($args->{'args'});
		$sth->execute(@bind) or croak("$query: ", join(', ', @bind));
	} else {
		$sth->execute() or croak($query);
	}

	# Fetch the results
	my @results;
	while (my $row = $sth->fetchrow_hashref()) {
		unless(wantarray) {
			$sth->finish();
			return $row;
		}
		push @results, $row;
	}

	# Return all rows as an array in list context
	return @results;
}

=head2 updated

Returns the Unix timestamp of the last database update (mtime for
file-based backends, or the time of the most recent C<new()> call for
DSN-based connections).

=cut

sub updated {
	my $self = shift;

	return $self->{'_updated'};
}

=head2 columns

Returns an array reference of column names for the current table.

    my $cols = $db->columns();    # e.g. ['entry', 'name', 'score', 'status']

The column list is determined by the backend:

=over 4

=item * B<Slurp mode> - sorted keys of the first row in memory.

=item * B<SQLite / other DBI> - a zero-row C<SELECT *> exposes the driver's
C<NAME> attribute.

=item * B<BerkeleyDB> - always returns C<['entry', 'value']>.

=back

The result is cached inside the object after the first call.

=cut

sub columns {
	my $self = shift;

	return $self->{'_columns'} if $self->{'_columns'};

	my $table = $self->_open_table({});

	my @cols;

	if($self->{'berkeley'}) {
		return $self->{'_columns'} = ['entry', 'value'];
	}

	if(my $data = $self->{'data'}) {
		if(ref($data) eq 'HASH') {
			my ($first) = values %{$data};
			@cols = sort keys %{$first} if $first;
		}
	} else {
		my $sth = $self->{$table}->prepare_cached("SELECT * FROM $table WHERE 1=0");
		$sth->execute();
		@cols = @{$sth->{NAME}};
		$sth->finish();
	}

	return $self->{'_columns'} = \@cols;
}

=head2 schema

Returns a hash reference describing the schema of the current table.
Each key is a column name; each value is a hash reference with these keys:

=over 4

=item * C<type> - data type string (e.g. C<TEXT>, C<INTEGER>, C<REAL>)

=item * C<nullable> - C<1> if the column may be NULL, C<0> if NOT NULL

=item * C<default> - default value string, or C<undef>

=item * C<pk> - C<1> if this column is (part of) the primary key, C<0> otherwise

=back

    my $schema = $db->schema();

    for my $col (sort keys %{$schema}) {
        my $info = $schema->{$col};
        printf "%s  %s  %s\n",
            $col,
            $info->{type},
            $info->{nullable} ? 'NULL' : 'NOT NULL';
    }

The schema is determined by the backend:

=over 4

=item * B<SQLite> - C<PRAGMA table_info(table)>

=item * B<Other DBI drivers> - C<< $dbh->column_info(...) >>

=item * B<Slurp mode> - inferred from the first row (all columns typed as C<TEXT>)

=item * B<BerkeleyDB> - always returns C<entry> (pk) and C<value>

=back

The result is cached inside the object after the first call.

=cut

sub schema {
	my $self = shift;

	return $self->{'_schema'} if $self->{'_schema'};

	my $table = $self->_open_table({});
	my %schema;

	if($self->{'berkeley'}) {
		return $self->{'_schema'} = {
			entry => { type => 'TEXT', nullable => 0, default => undef, pk => 1 },
			value => { type => 'TEXT', nullable => 1, default => undef, pk => 0 },
		};
	}

	if(my $data = $self->{'data'}) {
		if(ref($data) eq 'HASH') {
			my ($first) = values %{$data};
			if($first) {
				my $id = $self->{'id'};
				for my $col (keys %{$first}) {
					$schema{$col} = {
						type     => 'TEXT',
						nullable => ($col eq $id ? 0 : 1),
						default  => undef,
						pk       => ($col eq $id ? 1 : 0),
					};
				}
			}
		}
	} else {
		my $driver = $self->{$table}->{'Driver'}{'Name'} // '';
		if($driver eq 'SQLite') {
			my $sth = $self->{$table}->prepare_cached("PRAGMA table_info($table)");
			$sth->execute();
			while(my $row = $sth->fetchrow_hashref()) {
				$schema{$row->{'name'}} = {
					type     => $row->{'type'},
					nullable => !$row->{'notnull'},
					default  => $row->{'dflt_value'},
					pk       => $row->{'pk'},
				};
			}
			$sth->finish();
		} else {
			my $sth = $self->{$table}->column_info(undef, undef, $table, '%');
			if($sth) {
				while(my $row = $sth->fetchrow_hashref()) {
					$schema{$row->{'COLUMN_NAME'}} = {
						type     => $row->{'TYPE_NAME'},
						nullable => $row->{'NULLABLE'},
						default  => $row->{'COLUMN_DEF'},
						pk       => 0,
					};
				}
				$sth->finish();
			}
		}
	}

	return $self->{'_schema'} = \%schema;
}

=head2 query

Returns a new L<Database::Abstraction::Query> builder object bound to this
database instance, for fluent method-chaining queries.

    # All active rows with high scores, newest first, max 10
    my $rows = $db->query
        ->where(status => 'active')
        ->where(score  => { '>' => 80 })
        ->order_by('score DESC')
        ->limit(10)
        ->all();

    # Single row
    my $row = $db->query->where(name => 'Alice')->first();

    # Just a count
    my $n = $db->query->where(status => 'active')->count();

See L<Database::Abstraction::Query> for the full API.

=cut

sub query
{
	my $self = shift;
	require Database::Abstraction::Query;
	return Database::Abstraction::Query->new(_db => $self);
}

=head2 AUTOLOAD - column shortcut

Calling an unknown method whose name matches a column name performs a column
lookup.  The method name is the column you want; the arguments are criteria.

    # Scalar context: return the first match
    my $name = $db->name(entry => 'key1');

    # List context: return all matching values
    my @names = $db->name();

    # Shortcut when the table has an 'entry' key column
    my $name = $db->name('key1');    # same as name(entry => 'key1')

    # Unique/distinct values
    my @statuses = $db->status(distinct => 1);

B<In list context> the full column is returned (all rows), ordered by the
column value.  B<In scalar context> only the first match is returned
(C<LIMIT 1>).

Results come from the slurp cache when available.

Throws an error if the column does not exist (slurp mode) or if AUTOLOAD
has been disabled with C<< auto_load => 0 >>.

=head3 PSEUDOCODE

    1. Extract column name from $AUTOLOAD; guard on DESTROY.
    2. Croak if auto_load => 0.
    3. Validate $column against /^[a-zA-Z_][a-zA-Z0-9_]*$/.
    4. If data is slurped:
       a. List context, no params -> map column over all rows (exists guard).
       b. entry-only param -> direct hash lookup (exists guard).
       c. No params, scalar -> first value in hash.
       d. no_entry set -> scan array for matching key/value pair.
       e. Other params -> scan keyed hash for matching column.
    5. If not slurped, build SQL:
       - List:   SELECT column FROM table [WHERE ...] ORDER BY column
       - Scalar: SELECT DISTINCT column FROM table [WHERE ...] LIMIT 1
    6. Check cache; return on HIT.
    7. prepare_cached + execute; fetch result.
    8. Store in cache; fixate; return.

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my ($column) = $AUTOLOAD =~ /::(\w+)$/;

	return if($column eq 'DESTROY');

	my $self = shift or return;

	Carp::croak(__PACKAGE__, ": Unknown column $column") if(!ref($self));

	# Allow the AUTOLOAD feature to be disabled
	Carp::croak(__PACKAGE__, ": AUTOLOAD disabled (auto_load => 0)") if(exists($self->{'auto_load'}) && !$self->{'auto_load'});

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
			# Return all column values from the in-memory hash.
			# Use exists() because fixate() locks inner row hashes —
			# accessing a disallowed key would throw without the guard.
			# Handle both HASH (keyed data) and ARRAY (no_entry CSV slurp).
			my @_rows = ref($data) eq 'ARRAY' ? @{$data} : values %{$data};
			return map { exists($_->{$column}) ? $_->{$column} : undef } @_rows;
		}
		my $id = $self->{'id'};
		if(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
			$query = "SELECT $column FROM $table WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
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
						# exists() guards: fixate() locks row hashes recursively
						next unless exists($row->{$key}) && defined($row->{$key}) && $row->{$key} eq $value;
						my $rc = exists($row->{$column}) ? $row->{$column} : undef;
						$self->_trace(__LINE__, ": AUTOLOAD $key: return ", defined($rc) ? "'$rc'" : 'undef', ' from slurped data');
						return $rc;
					}
					$self->_debug('not found in slurped data');
				}
			} elsif(((scalar keys %params) == 1) && defined(my $key = $params{'entry'})) {
				# Look up a single entry by its key.
				# Use exists() before accessing — fixate() locks the outer hash and
				# dereferencing a missing key on a locked hash throws an exception.
				my $rc;
				if(exists($data->{$key}) && defined(my $hash = $data->{$key})) {
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
						my %h = map { $_ => 1 } grep { defined } map { exists($_->{$column}) ? $_->{$column} : undef } values %{$data};
						return keys %h;
					}
					# DEAD CODE: unreachable because the outer `if(wantarray && !$distinct)`
					# handles the wantarray+!distinct case. In this else branch, wantarray
					# implies $distinct (which returns above), so this line is never executed.
					# return map { exists($_->{$column}) ? $_->{$column} : undef } values %{$data}
				}
				# Scalar: return the first value found without building a full list
				foreach my $v (values %{$data}) {
					return exists($v->{$column}) ? $v->{$column} : undef;
				}
			} else {
				# Keyed data but filtering on a non-key column
				my ($key, $value) = %params;
				foreach my $row (values %{$data}) {
					next unless exists($row->{$key}) && defined($row->{$key}) && $row->{$key} eq $value;
					next unless exists($row->{$column});
					if(my $rc = $row->{$column}) {
						$self->_trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
						return $rc
					}
				}
			}
			return
		}
		# Data has not been slurped in
		my $id = $self->{'id'};
		if(($self->{'type'} eq 'CSV') && !$self->{'no_entry'}) {
			$query = "SELECT DISTINCT $column FROM $table WHERE $id IS NOT NULL AND $id NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT DISTINCT $column FROM $table";
		}
	}
	my @args;
	# Avoid `each` — it carries hidden iterator state across calls
	for my $k (sort keys %params) {
		# Guard against SQL injection via column names — same rule as _build_where_conditions
		Carp::croak(__PACKAGE__, ": unsafe column name '$k'")
			unless $k =~ /^[a-zA-Z_][a-zA-Z0-9_.]*$/;
		my $value = $params{$k};
		$self->_debug(__PACKAGE__, ": AUTOLOAD adding key/value pair $k=>", defined($value) ? $value : 'NULL');
		if(defined($value)) {
			$query .= $done_where ? " AND $k = ?" : " WHERE $k = ?";
			$done_where = 1;
			push @args, $value;
		} else {
			$query .= $done_where ? " AND $k IS NULL" : " WHERE $k IS NULL";
			$done_where = 1;
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
	my $sth = $self->{$table}->prepare_cached($query) || croak($query);
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
		# Store the value, then return it — cache->set() return value is unreliable
		$cache->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

sub DESTROY
{
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	# Clean up temporary file — deleting the File::Temp object triggers auto-unlink
	delete $self->{'_temp_fh'};

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

# Build the JOIN clause(s) from a single join hashref or arrayref of hashrefs.
# Each spec needs keys: table (required), on (required), type (default INNER).
sub _build_joins
{
	my ($self, $join_spec) = @_;

	my @specs = ref($join_spec) eq 'ARRAY' ? @{$join_spec} : ($join_spec);
	my %valid_types = map { $_ => 1 } qw(INNER LEFT RIGHT FULL CROSS);
	my @clauses;

	for my $j (@specs) {
		my $type  = uc($j->{'type'}  // 'INNER');
		my $jtable = $j->{'table'} or Carp::croak('join: missing "table"');
		Carp::croak("join: unsafe table name '$jtable'")
			unless $jtable =~ /^[a-zA-Z_][a-zA-Z0-9_.]*$/;
		my $on     = $j->{'on'}    or Carp::croak('join: missing "on" condition');
		Carp::croak("Invalid JOIN type: $type") unless $valid_types{$type};
		push @clauses, "$type JOIN $jtable ON ($on)";
	}

	return join(' ', @clauses);
}

# Return true when $params contains operator hashrefs, -or, or -and groupings
# that the simple slurp fast-path cannot handle.
sub _has_complex_criteria
{
	my ($self, $params) = @_;
	return 0 unless defined $params;
	return 1 if exists $params->{'-or'} || exists $params->{'-and'};
	for my $v (values %{$params}) {
		return 1 if ref($v);
	}
	return 0;
}

# Build the WHERE clause body (everything after "WHERE") from a criteria hash.
# Handles -or / -and groupings then delegates per-column work to _build_where_conditions.
# Returns ($sql_fragment, \@bind_values).
sub _build_where
{
	my ($self, $params) = @_;

	$params //= {};
	my %p = %{$params};	# work on a copy so we can delete -or/-and
	my @clauses;
	my @args;

	if(my $or_list = delete $p{'-or'}) {
		my (@sub_clauses, @sub_args);
		for my $cond (@{$or_list}) {
			my ($s, $a) = $self->_build_where_conditions($cond);
			if($s) {
				push @sub_clauses, "($s)";
				push @sub_args, @{$a};
			}
		}
		if(@sub_clauses) {
			push @clauses, '(' . join(' OR ', @sub_clauses) . ')';
			push @args, @sub_args;
		}
	}
	if(my $and_list = delete $p{'-and'}) {
		my (@sub_clauses, @sub_args);
		for my $cond (@{$and_list}) {
			my ($s, $a) = $self->_build_where_conditions($cond);
			if($s) {
				push @sub_clauses, "($s)";
				push @sub_args, @{$a};
			}
		}
		if(@sub_clauses) {
			push @clauses, '(' . join(' AND ', @sub_clauses) . ')';
			push @args, @sub_args;
		}
	}

	my ($more, $margs) = $self->_build_where_conditions(\%p);
	if($more) {
		push @clauses, $more;
		push @args, @{$margs};
	}

	return (join(' AND ', @clauses), \@args);
}

# Build a WHERE-body fragment for a flat col => val hash.
# Values may be plain scalars (= / LIKE / IS NULL) or operator hashrefs
# ({ '>' => n }, { -in => [...] }, { -between => [lo,hi] }, etc.).
sub _build_where_conditions
{
	my ($self, $params) = @_;

	my @clauses;
	my @args;

	for my $col (sort keys %{$params}) {
		my $val = $params->{$col};

		# Guard against SQL injection via column names; allow table.column notation for JOINs
		Carp::croak("_build_where_conditions: unsafe column name '$col'")
			unless $col =~ /^[a-zA-Z_][a-zA-Z0-9_.]*$/;

		if(ref($val) eq 'HASH') {
			for my $op (sort keys %{$val}) {
				my $operand = $val->{$op};
				if($op eq '-in' || $op eq '-not_in') {
					my $sql_op = $op eq '-in' ? 'IN' : 'NOT IN';
					my $ph = join(', ', ('?') x scalar(@{$operand}));
					push @clauses, "$col $sql_op ($ph)";
					push @args, @{$operand};
				} elsif($op eq '-between') {
					push @clauses, "$col BETWEEN ? AND ?";
					push @args, $operand->[0], $operand->[1];
				} elsif($op eq '-like') {
					push @clauses, "$col LIKE ?";
					push @args, $operand;
				} elsif($op eq '-not_like') {
					push @clauses, "$col NOT LIKE ?";
					push @args, $operand;
				} elsif($op eq '!=') {
					if(!defined($operand)) {
						push @clauses, "$col IS NOT NULL";
					} else {
						push @clauses, "$col != ?";
						push @args, $operand;
					}
				} elsif($op =~ /^(?:>|<|>=|<=)$/) {
					push @clauses, "$col $op ?";
					push @args, $operand;
				} else {
					Carp::croak("Unknown operator '$op' for column '$col'");
				}
			}
		} elsif(ref($val)) {
			Carp::croak("$col: expected scalar or operator hashref, got ", ref($val));
		} elsif(!defined($val)) {
			push @clauses, "$col IS NULL";
		} elsif($val =~ /[%_]/) {
			push @clauses, "$col LIKE ?";
			push @args, $val;
		} else {
			push @clauses, "$col = ?";
			push @args, $val;
		}
	}

	return (join(' AND ', @clauses), \@args);
}

# Test a single in-memory row value against a criteria value.
# $crit_val may be a plain scalar or an operator hashref.
# Returns true when the row value satisfies the criterion.
# Scan the entire BerkeleyDB tied hash, building rows as {entry=>$k, value=>$v},
# and filter by $params criteria using _match_criterion.
# Croaks when JOINs or -or/-and groupings are requested (unsupported for key-value stores).
sub _scan_berkeley
{
	my ($self, $params) = @_;
	$params //= {};

	if(delete $params->{'join'}) {
		Carp::croak(ref($self), ': BerkeleyDB does not support JOINs');
	}
	if(grep { $_ eq '-or' || $_ eq '-and' } keys %{$params}) {
		Carp::croak(ref($self), ': BerkeleyDB does not support -or/-and groupings');
	}

	my $bdb = $self->{'berkeley'};
	my @rows = map { { entry => $_, value => $bdb->{$_} } } keys %{$bdb};

	if(my @cols = keys %{$params}) {
		@rows = grep {
			my $row = $_;
			my $match = 1;
			for my $col (@cols) {
				unless($self->_match_criterion($row->{$col}, $params->{$col})) {
					$match = 0;
					last;
				}
			}
			$match;
		} @rows;
	}

	return \@rows;
}

# SQL LIKE match using dynamic programming (O(m*n), no catastrophic backtracking).
# % matches any sequence of chars; _ matches exactly one char.  Case-insensitive.
sub _like_match
{
	my ($str, $pattern) = @_;
	my @s = split //, lc($str);
	my @p = split //, lc($pattern);
	my $m = scalar @s;
	my $n = scalar @p;

	my @dp = map { [ (0) x ($m + 1) ] } 0 .. $n;
	$dp[0][0] = 1;

	for my $i (1 .. $n) {
		if($p[$i - 1] eq '%') {
			$dp[$i][0] = $dp[$i - 1][0];
			for my $j (1 .. $m) {
				$dp[$i][$j] = ($dp[$i - 1][$j] || $dp[$i][$j - 1]) ? 1 : 0;
			}
		} else {
			for my $j (1 .. $m) {
				$dp[$i][$j] = ($dp[$i - 1][$j - 1]
					&& ($p[$i - 1] eq '_' || $p[$i - 1] eq $s[$j - 1])) ? 1 : 0;
			}
		}
	}
	return $dp[$n][$m];
}

sub _match_criterion
{
	my ($self, $row_val, $crit_val) = @_;

	if(ref($crit_val) eq 'HASH') {
		for my $op (keys %{$crit_val}) {
			my $operand = $crit_val->{$op};
			if($op eq '-in') {
				return 0 unless defined($row_val) && grep { $row_val eq $_ } @{$operand};
			} elsif($op eq '-not_in') {
				return 0 if defined($row_val) && grep { $row_val eq $_ } @{$operand};
			} elsif($op eq '-between') {
				return 0 unless defined($row_val) && $row_val >= $operand->[0] && $row_val <= $operand->[1];
			} elsif($op eq '-like') {
				return 0 unless defined($row_val);
				return 0 unless _like_match($row_val, $operand);
			} elsif($op eq '-not_like') {
				return 0 unless defined($row_val);
				return 0 if _like_match($row_val, $operand);
			} elsif($op eq '!=') {
				if(!defined($operand)) {
					return 0 unless defined($row_val);
				} else {
					return 0 unless defined($row_val) && $row_val ne $operand;
				}
			} elsif($op eq '>') {
				return 0 unless defined($row_val) && $row_val > $operand;
			} elsif($op eq '<') {
				return 0 unless defined($row_val) && $row_val < $operand;
			} elsif($op eq '>=') {
				return 0 unless defined($row_val) && $row_val >= $operand;
			} elsif($op eq '<=') {
				return 0 unless defined($row_val) && $row_val <= $operand;
			}
		}
		return 1;
	}

	return !defined($row_val) && !defined($crit_val) ? 1
		: !defined($row_val) || !defined($crit_val) ? 0
		: $row_val eq $crit_val;
}

# Determine the table and open the database
sub _open_table
{
	my($self, $params) = @_;

	# Get table name (remove package name prefix if present)
	my $table = $params->{'table'} || $self->{'table'} || ref($self);
	$table =~ s/.*:://;

	# Open a connection if it's not already open.
	# BerkeleyDB never sets $self->{$table} (no DBI handle) or $self->{'data'},
	# so we also guard on $self->{'berkeley'} to avoid re-tying on every call.
	$self->_open() if((!$self->{$table}) && (!$self->{'data'}) && (!$self->{'berkeley'}));

	return $table;
}

# Quote a SQL identifier using the current connection's dialect rules.
# Falls back to ANSI double-quoting when no connection is available.
sub _quote_identifier
{
	my ($self, $name) = @_;

	my $table = $self->{'table'} || ref($self);
	$table =~ s/.*:://;
	if(my $dbh = $self->{$table}) {
		return $dbh->quote_identifier($name);
	}
	return qq{"$name"};
}

# Determine whether a given file is a valid Berkeley DB file.
# It combines a fast preliminary check with a more thorough validation step for accuracy.
# It looks for the magic number at both byte 0 and byte 12
# TODO: Combine _db_0 and _db_12 as they are very similar routines
sub _is_berkeley_db {
	my ($self, $file) = @_;

	# Step 1: Check magic number
	# no autodie here: the file may not exist, and we want a silent false return
	my $fh;
	do { no autodie qw(open); open $fh, '<', $file } or return 0;
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
	my $params = Params::Get::get_params('warning', \@_);

	$self->_log('warn', $params->{'warning'});
	Carp::carp(join('', grep defined, $params->{'warning'}));
}

# Die
sub _fatal {
	my $self = shift;
	my $params = Params::Get::get_params('warning', \@_);

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

=head1 MESSAGES

The table below lists every error that the module can croak or carp, what
triggers it, and how to resolve it.

=over 4

=item C<< I<Class>: abstract class >>

Direct instantiation of C<Database::Abstraction> was attempted.
Create a subclass and instantiate that instead.

=item C<< I<Class>: where are the files? >>

Neither C<directory> nor C<dsn> was supplied to C<new()>.

=item C<< I<Class>: I</path> is not a directory >>

The C<directory> argument exists on disk but is not a directory.

=item C<< I<Class>: cannot connect: I<$DBI::errstr> >>

DBI failed to connect to the given C<dsn>.  Check credentials and host.

=item C<< Can't find a file called 'I<name>' for the table I<T> in I<dir> >>

None of the probe extensions (C<.sql>, C<.psv>, C<.csv>, C<.db>, C<.xml>)
matched in C<directory>.

=item C<< I<Class>: prepare failed: I<$errstr> >>

C<prepare_cached()> returned false.  Usually a syntax error in an internally
built query; file a bug if you see this from a normal API call.

=item C<< _build_where_conditions: unsafe column name 'I<name>' >>

A criteria key contained characters outside C<[A-Za-z0-9_.]>.
This is a SQL-injection guard.  Use only valid SQL identifier characters.

=item C<< join: missing "table" >> / C<< join: missing "on" condition >>

A join spec hashref is incomplete.  Both C<table> and C<on> are required.

=item C<< Invalid JOIN type: I<TYPE> >>

C<type> in a join spec was not one of C<INNER LEFT RIGHT FULL CROSS>.

=item C<< I<Class>: Unknown column I<col> >> / C<< I<Class>: AUTOLOAD disabled >>

An AUTOLOAD call was made for a column that does not exist, or AUTOLOAD
was disabled with C<< auto_load => 0 >>.

=item C<< Usage: set_logger(logger => $logger) >>

C<set_logger()> was called without a C<logger> argument.

=item C<< Usage: execute(query => $query) >>

C<execute()> was called without a C<query> argument.

=item C<< XML slurp: I<...> is not yet supported >>

The XML file structure is too complex for slurp mode.
Use C<< max_slurp_size => 0 >> to force the DBI/XMLSimple SQL path.

=item C<< I<Class>: I<method> is meaningless on a NoSQL database >>

A relational method (C<selectall_arrayref>, C<count>, C<execute>, etc.)
was called on a BerkeleyDB backend, which only supports key-value lookup
via C<fetchrow_hashref>.

=back

=head1 KNOWN LIMITATIONS

=over 4

=item *

B<Read-only.>  No INSERT, UPDATE, or DELETE is provided.  C<execute()>
runs raw read-only SQL.

=item *

B<Default CSV separator is C<!>>, not C<,>, for historical reasons.
Pass C<< sep_char => ',' >> for standard RFC 4180 files.

=item *

B<Primary-key column is named C<entry>>, not C<key>, because C<key>
is a SQL reserved word.  Override with the C<id> parameter.

=item *

B<XML slurp is limited.>  Only simple flat XML structures are supported
in slurp mode.  Multi-key or deeply nested documents will croak.
Force SQL mode with C<< max_slurp_size => 0 >> if slurp fails.

=item *

B<Unique key assumption in slurp mode.>  Duplicate values in the key
column silently overwrite earlier rows.  Disable slurp with
C<< max_slurp_size => 0 >> if duplicates are expected.

=item *

B<BerkeleyDB does not support joins or the chained query builder.>

=item *

B<Column names must be valid SQL identifiers> (letters, digits,
underscores, and a single dot for C<table.column> join notation).
Other characters will cause a croak.

=item *

B<count() cache is opportunistic.>  Count results are served from cache
only when a prior C<selectall_arrayref()> or C<count()> call with the
same criteria has already populated it.

=back

=head1 SEE ALSO

=over 4

=item * L<Database::Abstraction::Query> - chained query builder

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Database-Abstraction/coverage/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
