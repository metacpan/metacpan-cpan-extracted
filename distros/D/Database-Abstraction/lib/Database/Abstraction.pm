package Database::Abstraction;

=head1 NAME

Database::Abstraction - database abstraction layer

=cut

# Author Nigel Horne: njh@bandsman.co.uk
# Copyright (C) 2015-2024, Nigel Horne

# Usage is subject to licence terms.
# The licence terms of this software are as follows:
# Personal single user, single computer use: GPL2
# All other users (for example Commercial, Charity, Educational, Government)
#	must apply in writing for a licence for use from Nigel Horne at the
#	above e-mail.

# TODO: Switch "entry" to off by default, and enable by passing 'entry'
#	though that wouldn't be so nice for AUTOLOAD
# TODO: support a directory hierarchy of databases
# TODO: consider returning an object or array of objects, rather than hashes
# TODO:	Add redis database - could be of use for Geo::Coder::Free
#	use select() to select a database - use the table arg
#	new(database => 'redis://servername');
# TODO:	Add a "key" property, defaulting to "entry", which would be the name of the key
# TODO:	The maximum number to return should be tuneable (as a LIMIT)
# FIXME:	t/xml.t fails in slurping mode

use warnings;
use strict;

use Data::Dumper;
use DBD::SQLite::Constants qw/:file_open/;	# For SQLITE_OPEN_READONLY
use File::Basename;
use File::Spec;
use File::pfopen 0.03;	# For $mode and list context
use File::Temp;
# use Error::Simple;	# A nice idea to use this but it doesn't play well with "use lib"
use Carp;

our %defaults;
use constant	DEFAULT_MAX_SLURP_SIZE => 16 * 1024;	# CSV files <= than this size are read into memory

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

Abstract class giving read-only access to CSV, XML and SQLite databases via Perl without writing any SQL.
Look for databases in $directory in this order:
1) SQLite (file ends with .sql)
2) PSV (pipe separated file, file ends with .psv)
3) CSV (file ends with .csv or .db, can be gzipped) (note the default sep_char is '!' not ',')
4) XML (file ends with .xml)

For example, you can access the files in /var/db/foo.csv via this class:

    package MyPackageName::Database::Foo;

    use Database::Abstraction;

    our @ISA = ('Database::Abstraction');

You can then access the data using:

    my $foo = MyPackageName::Database::Foo->new(directory => '/var/dat');
    print 'Customer name ', $foo->name(customer_id => 'plugh'), "\n";
    my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');
    print Data::Dumper->new([$row])->Dump();

If the table has a key column,
entries are keyed on that and sorts are based on it.
To turn that off, pass 'no_entry' to the constructor, for legacy
reasons it's enabled by default.
The key column's default name is 'entry', but it can be overridden by the 'id' parameter.

CSV files that are not no_entry can have empty lines or comment lines starting with '#',
to make them more readable.

=head1 SUBROUTINES/METHODS

=head2 init

Set some class level defaults.

    MyPackageName::Database::init(directory => '../data');

See the documentation for new to see what variables can be set.

Returns a reference to a hash of the current values.
Therefore when given with no arguments you can get the current default values:

    my $defaults = Database::Abstraction::init();
    print $defaults->{'directory'}, "\n";

=cut

# Subroutine to initialize with args
sub init
{
	if(scalar(@_)) {
		my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

		# $defaults->{'directory'} ||= $args{'directory'};
		# $defaults->{'logger'} ||= $args{'logger'};
		# $defaults->{'cache'} ||= $args{'cache'};
		# $defaults->{'cache_duration'} ||= $args{'cache_duration'};
		%defaults = (%defaults, %args)
	}

	return \%defaults
}

=head2 new

Create an object to point to a read-only database.

Arguments:

cache => place to store results;
cache_duration => how long to store results in the cache (default is 1 hour);
directory => where the database file is held
max_slurp_size => CSV/PSV/XML files smaller than this are held in RAM (default is 16K)

If the arguments are not set, tries to take from class level defaults.

    # Regular CSV: There is no entry column and the separators are commas
    sub new
    {
	my $class = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

=cut

sub new {
	my $class = shift;
	my %args;

	if(ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} elsif((scalar(@_) % 2) == 0) {
		%args = @_;
	} elsif(scalar(@_) == 1) {
		$args{'directory'} = shift;
	}

	if(!defined($class)) {
		# Using Database::Abstraction->new(), not Database::Abstraction::new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif($class eq __PACKAGE__) {
		croak("$class: abstract class");
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %args }, ref($class);
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
	return bless {
		no_entry => 0,
		id => 'entry',
		cache_duration => '1 hour',
		max_slurp_size => DEFAULT_MAX_SLURP_SIZE,
		%defaults,
		%args
	}, $class;
}

=head2	set_logger

Pass a class that will be used for logging.

=cut

sub set_logger
{
	my $self = shift;
	my $args = $self->_get_params('logger', @_);

	if(defined($args->{'logger'})) {
		$self->{'logger'} = $args->{'logger'};
		return $self;
	}
	Carp::croak('Usage: set_logger(logger => $logger)')
}

# Open the database.

sub _open {
	my $self = shift;
	my $sep_char = ($self->{'sep_char'} ? $self->{'sep_char'} : '!');
	my %args = (
		sep_char => $sep_char,
		((ref($_[0]) eq 'HASH') ? %{$_[0]} : @_)
	);

	my $table = $self->{'table'} || ref($self);
	$table =~ s/.*:://;

	if($self->{'logger'}) {
		$self->{'logger'}->trace("_open $table");
	}
	return if($self->{$table});

	# Read in the database
	my $dbh;

	my $dir = $self->{'directory'} || $defaults{'directory'};
	my $slurp_file = File::Spec->catfile($dir, "$table.sql");
	if($self->{'logger'}) {
		$self->{'logger'}->debug("_open: try to open $slurp_file");
	}

	if(-r $slurp_file) {
		require DBI;

		DBI->import();

		$dbh = DBI->connect("dbi:SQLite:dbname=$slurp_file", undef, undef, {
			sqlite_open_flags => SQLITE_OPEN_READONLY,
		});
		$dbh->do('PRAGMA synchronous = OFF');
		$dbh->do('PRAGMA cache_size = 65536');
		if($self->{'logger'}) {
			$self->{'logger'}->debug("read in $table from SQLite $slurp_file");
		}
		$self->{'type'} = 'DBI';
	} else {
		my $fin;
		($fin, $slurp_file) = File::pfopen::pfopen($dir, $table, 'csv.gz:db.gz', '<');
		if(defined($slurp_file) && (-r $slurp_file)) {
			require Gzip::Faster;
			Gzip::Faster->import();

			close($fin);
			$fin = File::Temp->new(SUFFIX => '.csv', UNLINK => 0);
			print $fin gunzip_file($slurp_file);
			$slurp_file = $fin->filename();
			$self->{'temp'} = $slurp_file;
		} else {
			($fin, $slurp_file) = File::pfopen::pfopen($dir, $table, 'psv', '<');
			if(defined($fin)) {
				# Pipe separated file
				$args{'sep_char'} = '|';
			} else {
				($fin, $slurp_file) = File::pfopen::pfopen($dir, $table, 'csv:db', '<');
			}
		}
		if(defined($slurp_file) && (-r $slurp_file)) {
			close($fin);
			$sep_char = $args{'sep_char'};
			if($self->{'logger'}) {
				$self->{'logger'}->debug(__LINE__, ' of ', __PACKAGE__, ": slurp_file = $slurp_file, sep_char = $sep_char");
			}
			if($args{'column_names'}) {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef,
					{
						csv_sep_char => $sep_char,
						csv_tables => {
							$table => {
								col_names => $args{'column_names'},
							},
						},
					}
				);
			} else {
				$dbh = DBI->connect("dbi:CSV:db_name=$slurp_file", undef, undef, { csv_sep_char => $sep_char});
			}
			$dbh->{'RaiseError'} = 1;

			if($self->{'logger'}) {
				$self->{'logger'}->debug("read in $table from CSV $slurp_file");
			}

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

			# FIXME: Text::xSV::Slurp can't cope well with quotes in field contents
			if((-s $slurp_file) <= $self->{'max_slurp_size'}) {
				require Text::xSV::Slurp;
				Text::xSV::Slurp->import();

				if($self->{'logger'}) {
					$self->{'logger'}->trace('slurp in');
				}
				my @data = @{xsv_slurp(
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
				)};

				# $self->{'data'} = @data;
				if($self->{'no_entry'}) {
					# Not keyed, will need to scan each entry
					my $i = 0;
					$self->{'data'} = ();
					foreach my $d(@data) {
						$self->{'data'}[$i++] = $d;
					}
				} else {
					# keyed on the $self->{'id'} (default: "entry") column
					# Ignore blank lines or lines starting with # in the CSV file
					@data = grep { $_->{$self->{'id'}} !~ /^\s*#/ } grep { defined($_->{$self->{'id'}}) } @data;
					foreach my $d(@data) {
						$self->{'data'}->{$d->{$self->{'id'}}} = $d;
					}
				}
			}
			$self->{'type'} = 'CSV';
		} else {
			$slurp_file = File::Spec->catfile($dir, "$table.xml");
			if(-r $slurp_file) {
				if((-s $slurp_file) <= $self->{'max_slurp_size'}) {
					require XML::Simple;
					XML::Simple->import();

					my $xml = XMLin(File::Spec->catfile($dir, "$table.xml"));
					my @keys = keys %{$xml};
					my $key = $keys[0];
					my @data;
					if(ref($xml->{$key}) eq 'ARRAY') {
						@data = @{$xml->{$key}};
					} else {
						@data = @{$xml};
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
					if($self->{'logger'}) {
						$self->{'logger'}->debug("read in $table from XML $slurp_file");
					}
					$dbh->func($table, 'XML', $slurp_file, 'xmlsimple_import');
				}
			} else {
				# throw Error(-file => "$dir/$table");
				croak("Can't find a $table database in $dir");
			}
			$self->{'type'} = 'XML';
		}
	}

	$self->{$table} = $dbh;
	my @statb = stat($slurp_file);
	$self->{'_updated'} = $statb[9];

	return $self;
}

=head2	selectall_hashref

Returns a reference to an array of hash references of all the data meeting
the given criteria.

Note that since this returns an array ref,
optimisations such as "LIMIT 1" will not be used.

=cut

sub selectall_hashref {
	my $self = shift;

	my @rc = $self->selectall_hash(@_);
	return \@rc;
}

=head2	selectall_hash

Returns an array of hash references

=cut

sub selectall_hash
{
	my $self = shift;
	my $params = $self->_get_params(undef, @_);

	my $table = $self->{table} || ref($self);
	$table =~ s/.*:://;

	$self->_open() if((!$self->{$table}) && (!$self->{'data'}));

	if($self->{'data'}) {
		if(scalar(keys %{$params}) == 0) {
			if($self->{'logger'}) {
				$self->{'logger'}->trace("$table: selectall_hash fast track return");
			}
			return values %{$self->{'data'}};
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
			if($self->{'logger'}) {
				$self->{'logger'}->fatal("selectall_hash $query: argument is not a string");
			}
			# throw Error::Simple("$query: argument is not a string: " . ref($arg));
			croak("$query: argument is not a string: ", ref($arg));
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
		if($arg =~ /\@/) {
			$query .= " $keyword $c1 LIKE ?";
		} else {
			$query .= " $keyword $c1 = ?";
		}
		push @query_args, $arg;
	}
	if(!$self->{no_entry}) {
		$query .= ' ORDER BY ' . $self->{'id'};
	}
	if(!wantarray) {
		$query .= ' LIMIT 1';
	}
	if($self->{'logger'}) {
		if(defined($query_args[0])) {
			$self->{'logger'}->debug("selectall_hash $query: ", join(', ', @query_args));
		} else {
			$self->{'logger'}->debug("selectall_hash $query");
		}
	}
	my $key;
	my $c;
	if($c = $self->{cache}) {
		$key = $query;
		if(defined($query_args[0])) {
			$key .= ' ' . join(', ', @query_args);
		}
		if(my $rc = $c->get($key)) {
			if($self->{'logger'}) {
				$self->{'logger'}->debug('cache HIT');
			}
			# This use of a temporary variable is to avoid
			#	"Implicit scalar context for array in return"
			# return @{$rc};
			my @rc = @{$rc};
			return @rc;
		}
		if($self->{'logger'}) {
			$self->{'logger'}->debug('cache MISS');
		}
	} elsif($self->{'logger'}) {
		$self->{'logger'}->debug('cache not used');
	}

	if(my $sth = $self->{$table}->prepare($query)) {
		$sth->execute(@query_args) ||
			# throw Error::Simple("$query: @query_args");
			croak("$query: @query_args");

		my @rc;
		while(my $href = $sth->fetchrow_hashref()) {
			# FIXME: Doesn't store in the cache
			return $href if(!wantarray);
			push @rc, $href;
		}
		if($c && wantarray) {
			$c->set($key, \@rc, $self->{'cache_duration'});
		}

		return @rc;
	}
	if($self->{'logger'}) {
		$self->{'logger'}->warn("selectall_hash failure on $query: @query_args");
	}
	# throw Error::Simple("$query: @query_args");
	croak("$query: @query_args");
}

=head2	fetchrow_hashref

Returns a hash reference for one row in a table.
Special argument: table: determines the table to read from if not the default,
which is worked out from the class name

=cut

sub fetchrow_hashref {
	my $self = shift;
	my $params = $self->_get_params(undef, @_);

	my $table = $params->{'table'} || $self->{'table'} || ref($self);
	$table =~ s/.*:://;

	if($self->{'data'} && (!$self->{'no_entry'}) && (scalar keys(%{$params}) == 1) && defined($params->{'entry'})) {
		if(my $logger = $self->{'logger'}) {
			$logger->debug('Fast return from slurped data');
		}
		return $self->{'data'}->{$params->{'entry'}};
	}

	my $query = 'SELECT * FROM ';
	if(my $t = delete $params->{'table'}) {
		$query .= $t;
	} else {
		$query .= $table;
	}
	my $done_where = 0;

	$self->_open() if(!$self->{$table});

	if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
		$query .= ' WHERE ' . $self->{'id'} . ' IS NOT NULL AND ' . $self->{'id'} . " NOT LIKE '#%'";
		$done_where = 1;
	}
	my @query_args;
	foreach my $c1(sort keys(%{$params})) {	# sort so that the key is always the same
		if(my $arg = $params->{$c1}) {
			my $keyword;

				if(ref($arg)) {
					if($self->{'logger'}) {
						$self->{'logger'}->fatal("selectall_hash $query: argument is not a string");
					}
					# throw Error::Simple("$query: argument is not a string: " . ref($arg));
					croak("$query: argument is not a string: ", ref($arg));
				}
			if($done_where) {
				$keyword = 'AND';
			} else {
				$keyword = 'WHERE';
				$done_where = 1;
			}
			if($arg =~ /\@/) {
				$query .= " $keyword $c1 LIKE ?";
			} else {
				$query .= " $keyword $c1 = ?";
			}
			push @query_args, $arg;
		} elsif(!defined($arg)) {
			my @call_details = caller(0);
			# throw Error::Simple("$query: value for $c1 is not defined in call from " .
				# $call_details[2] . ' of ' . $call_details[1]);
			Carp::croak("$query: value for $c1 is not defined in call from ",
				$call_details[2], ' of ', $call_details[1]);
		}
	}
	# $query .= ' ORDER BY entry LIMIT 1';
	$query .= ' LIMIT 1';
	if($self->{'logger'}) {
		if(defined($query_args[0])) {
			my @call_details = caller(0);
			$self->{'logger'}->debug("fetchrow_hashref $query: ", join(', ', @query_args),
				' called from ', $call_details[2], ' of ', $call_details[1]);
		} else {
			$self->{'logger'}->debug("fetchrow_hashref $query");
		}
	}
	my $key;
	if(defined($query_args[0])) {
		$key = "fetchrow $query " . join(', ', @query_args);
	} else {
		$key = "fetchrow $query";
	}
	my $c;
	if($c = $self->{cache}) {
		if(my $rc = $c->get($key)) {
			return $rc;
		}
	}

	my $sth = $self->{$table}->prepare($query) or die $self->{$table}->errstr();
	# $sth->execute(@query_args) || throw Error::Simple("$query: @query_args");
	$sth->execute(@query_args) || croak("$query: @query_args");
	my $rc = $sth->fetchrow_hashref();
	if($c) {
		if(my $logger = $self->{'logger'}) {
			if($rc) {
				$logger->debug("stash $key=>$rc in the cache for ", $self->{'cache_duration'});
				$logger->debug("returns ", Data::Dumper->new([$rc])->Dump());
			} else {
				$logger->debug("Stash $key=>undef in the cache for ", $self->{'cache_duration'});
			}
		}
		$c->set($key, $rc, $self->{'cache_duration'});
	}
	return $rc;
}

=head2	execute

Execute the given SQL on the data.
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
	my $args = $self->_get_params('query', @_);

	# Ensure the 'query' parameter is provided
	Carp::croak(__PACKAGE__, ': Usage: execute(query => $query)') 
		unless defined $args->{'query'};

	# Get table name (remove package name prefix if present)
	my $table = $self->{table} || ref($self);
	$table =~ s/.*:://;

	# Open a connection if it's not already open
	$self->_open() unless $self->{$table};

	my $query = $args->{'query'};

	# Append "FROM <table>" if missing
	$query .= " FROM $table" unless $query =~ /\sFROM\s/i;

	# Log the query if a logger is available
	$self->{'logger'}->debug("execute $query") if $self->{'logger'};

	# Prepare and execute the query
	my $sth = $self->{$table}->prepare($query);
	$sth->execute() or croak($query);  # Die with the query in case of error

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

Time that the database was last updated

=cut

sub updated {
	my $self = shift;

	return $self->{'_updated'};
}

=head2 AUTOLOAD

Return the contents of an arbitrary column in the database which match the
given criteria
Returns an array of the matches,
or only the first when called in scalar context

If the database has a column called "entry" you can do a quick lookup with

    my $value = $foo->column('123');	# where "column" is the value you're after
    my @entries = $foo->entry();
    print 'There are ', scalar(@entries), " entries in the database\n";

Set distinct or unique to 1 if you're after a unique list.

=cut

sub AUTOLOAD {
	our $AUTOLOAD;
	my ($column) = $AUTOLOAD =~ /::(\w+)$/;

	return if($column eq 'DESTROY');

	my $self = shift or return;

	my $table = $self->{table} || ref($self);
	$table =~ s/.*:://;

	my %params;
	if(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif((scalar(@_) % 2) == 0) {
		%params = @_;
	} elsif(scalar(@_) == 1) {
		if($self->{'no_entry'}) {
			Carp::croak(ref($self), "::($_[0]): ", $self->{'id'}, 'is not a column');
		}
		$params{'entry'} = shift;
	}

	$self->_open() if(!$self->{$table});

	my $query;
	my $done_where = 0;
	my $distinct = delete($params{'distinct'}) || delete($params{'unique'});

	if(wantarray && !$distinct) {
		if(((scalar keys %params) == 0) && (my $data = $self->{'data'})) {
			# Return all the entries in the column
			return map { $_->{$column} } values %{$data};
		}
		if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
			$query = "SELECT $column FROM $table WHERE " . $self->{'id'} . "IS NOT NULL AND entry NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT $column FROM $table";
		}
	} else {
		if(my $data = $self->{'data'}) {
			# The data has been read in using Text::xSV::Slurp, and it's a simple query
			#	so no need to do any SQL
			if($self->{'no_entry'}) {
				my ($key, $value) = %params;
				foreach my $row(@{$data}) {
					if(($row->{$key} eq $value) && (my $rc = $row->{$column})) {
						if($self->{'logger'}) {
							if(defined($rc)) {
								$self->{'logger'}->trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
							} else {
								$self->{'logger'}->trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
							}
						}
						return $rc
					}
				}
			} elsif(((scalar keys %params) == 1) && defined(my $key = $params{'entry'})) {
				# Look up the key

				# This weird code is to stop the data hash becoming polluted with empty
				#	values as we look things up
				# my $rc = $data->{$key}->{$column};
				my $rc;
				if(defined(my $hash = $data->{$key})) {
					$rc = $hash->{$column};
				}
				if($self->{'logger'}) {
					if(defined($rc)) {
						$self->{'logger'}->trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
					} else {
						$self->{'logger'}->trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
					}
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
					if(($row->{$key} eq $value) && (my $rc = $row->{$column})) {
						if($self->{'logger'}) {
							if(defined($rc)) {
								$self->{'logger'}->trace(__LINE__, ": AUTOLOAD $key: return '$rc' from slurped data");
							} else {
								$self->{'logger'}->trace(__LINE__, ": AUTOLOAD $key: return undef from slurped data");
							}
						}
						return $rc
					}
				}
			}
			return
		}
		if(($self->{'type'} eq 'CSV') && !$self->{no_entry}) {
			$query = "SELECT DISTINCT $column FROM $table WHERE " . $self->{'id'} . "IS NOT NULL AND entry NOT LIKE '#%'";
			$done_where = 1;
		} else {
			$query = "SELECT DISTINCT $column FROM $table";
		}
	}
	my @args;
	while(my ($key, $value) = each %params) {
		if($self->{'logger'}) {
			$self->{'logger'}->debug(__PACKAGE__, ": AUTOLOAD adding key/value pair $key=>$value");
		}
		if(defined($value)) {
			if($done_where) {
				$query .= " AND $key = ?";
			} else {
				$query .= " WHERE $key = ?";
				$done_where = 1;
			}
			push @args, $value;
		} else {
			if($self->{'logger'}) {
				$self->{'logger'}->debug("AUTOLOAD params $key isn't defined");
			}
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
	if($self->{'logger'}) {
		if(scalar(@args) && $args[0]) {
			$self->{'logger'}->debug("AUTOLOAD $query: ", join(', ', @args));
		} else {
			$self->{'logger'}->debug("AUTOLOAD $query");
		}
	}
	# my $sth = $self->{$table}->prepare($query) || throw Error::Simple($query);
	my $sth = $self->{$table}->prepare($query) || croak($query);
	# $sth->execute(@args) || throw Error::Simple($query);
	$sth->execute(@args) || croak($query);

	if(wantarray) {
		return map { $_->[0] } @{$sth->fetchall_arrayref()};
	}
	return $sth->fetchrow_array();	# Return the first match only
}

sub DESTROY {
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	if($self->{'temp'}) {
		unlink delete $self->{'temp'};
	}
	if(my $table = delete $self->{'table'}) {
		$table->finish();
	}
}

# Helper routine to parse the arguments given to a function,
#	allowing the caller to call the function in anyway that they want
#	e.g. foo('bar'), foo(arg => 'bar'), foo({ arg => 'bar' }) all mean the same
#	when called _get_params('arg', @_);
sub _get_params
{
	shift;  # Discard the first argument (typically $self)
	my $default = shift;

	# Directly return hash reference if the first parameter is a hash reference
	return $_[0] if ref $_[0] eq 'HASH';

	my %rc;
	my $num_args = scalar @_;

	# Populate %rc based on the number and type of arguments
	if(($num_args == 1) && (defined $default)) {
		# %rc = ($default => shift);
		return { $default => shift };
	} elsif($num_args == 1) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	} elsif($num_args == 0 && defined $default) {
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '($default => \$val)');
	} elsif(($num_args % 2) == 0) {
		%rc = @_;
	}

	return \%rc;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

The default delimiter for CSV files is set to '!', not ',' for historical reasons.
I really ought to fix that.

It would be nice for the key column to be called key, not entry,
however key's a reserved word in SQL.

The no_entry parameter should be no_id.

XML slurping is hard,
so if XML fails for you on a small file force non-slurping mode with

    $foo = MyPackageName::Database::Foo->new({
	directory => '/var/db',
	# max_slurp_size => 1	# force to not use slurp and therefore to use SQL
    });

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2024 Nigel Horne.

This program is released under the following licence: GPL2.
Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (for example Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.

=cut

1;
