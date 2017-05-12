package DBIx::Librarian;

require 5.005;
use strict;
#use warnings;			# needs 5.6
use vars qw($VERSION);

$VERSION = '0.6';

use Data::Library::OnePerFile;	# default archiver
use DBIx::Librarian::Statement;

=head1 NAME

DBIx::Librarian - Manage SQL in repository outside code

=head1 SYNOPSIS

  use DBIx::Librarian;

  my $dblbn = new DBIx::Librarian;

  my $data = { id => 473 };
  eval { $dblbn->execute("lookup_employee", $data); };
  die $@ if $@;
  print "Employee $data->{id} is $data->{name}\n";

  $dblbn->disconnect;

=head1 OBJECTIVES

Separation of database logic from application logic (SQL from Perl)

Simple interface - sacrifices some flexibility in exchange for
code readability and development speed

Leave SQL syntax untouched if possible; support any extensions that are
supported by the underlying database

Support transaction capability if the database allows it

This is NOT an object-to-relational-mapping toolkit or a persistence
framework.  For that sort of thing, see SPOPS or any of several other
excellent modules.  The combination of DBIx::Librarian and Template
Toolkit or one of the other templating packages will give the basis
of a fairly comprehensive database-driven application framework.

=head1 FEATURES

=over

=item *

Support full complexity of Perl associative data structures

=item *

Multiple SQL statements chained in a single execute() invocation.
Use results from one call as inputs to the next.

=item *

Each execute() is automatically a transaction, comprising one or
more statements per the above.  Optional delayed commit to
collect multiple invocations into a transaction.  Note that if your
database doesn't support transactions (e.g. vanilla mySQL), then
you're still out of luck here.

=item *

Processing modes for select statements: exactly one row, zero-or-one,
multiple rows (zero to many); optional exception on receiving multiple
rows when expecting just one.  SQL syntax is extended to provide these
controls.

=item *

Support bind variables, and on-the-fly SQL generation through substitution
of entire SQL fragments.

=item *

Supports multiple repositories for queries - currently supports
individual files and multiple-query files.

=item *

Database connection can be passed into the Librarian initializer, or
it will create it internally.

=item *

If the database connection is down when execute() is called, Librarian
will attempt to re-connect.

=item *

Sets DBI LongReadLen and LongTruncOk to allow for fetching long values.
Optional LONGREADLEN parameter to DBIx::Librarian::new will be passed
through to DBI (default 1000).

=back

=head1 ENVIRONMENT VARIABLES

DBIx::Librarian will use the following:

  DBI_DSN       standard DBI connection parameters
  DBI_USER
  DBI_PASS


=head1 DESCRIPTION

This is for data manipulation (SELECT, INSERT, UPDATE, DELETE), not for
data definition (CREATE, DROP, ALTER).  Some DDL statements may work
inside this module, but correct behavior is not guaranteed.

Results of "SELECT1 colname FROM table", expected to return a single row:

    {
      colname => "value"
    }

  Access via $data->{colname}

  If more than one row is returned, raise an exception.

Results of "SELECT* colname FROM table", expected to return multiple rows
(note alteration to standard SQL syntax):

  [
    {
      colname => "vala"
    },
    {
      colname => "valb"
    },
    {
      colname => "valc"
    }
  ]

  Access via $data->[n]->{colname}

Results of "SELECT1 col1, col2 FROM table", expected to return a single row:

    {
      col1 => "valA",
      col2 => "valB",
    }

  Access via $data->{colname}

  If more than one row is returned, raise an exception.

Results of

    SELECT*  col1 "record.col1",
             col2 "record.col2",
             col3 "record.col3"
    FROM table

expected to return multiple rows:

  {
    record =>
      [
        {
          col1 => "val1a",
          col2 => "val2a",
          col3 => "val3a"
        },
        {
          col1 => "val1b",
          col2 => "val2b",
          col3 => "val3b"
        },
        {
          col1 => "val1c",
          col2 => "val2c",
          col3 => "val3c"
        },
      ]
  }

  Access via $data->{record}[n]->{colname}

=head1 TO DO

=over

=item *

Endeavor to consolidate some of this work with other similar modules

=item *

Optional constraint on number of rows returned by SELECT statements

=item *

Optional cancellation of long-running queries

=item *

Verbosity controls for logging during initialization and query execution;
tie in with DBI tracing

=item *

Limits on number of cached statement handles.  Some databases may place
limits on the number of concurrent handles.  Some sort of LRU stack of
handles would be useful for this.

=item *

Consider whether DBI Taint mode would be appropriate here.

=item *

Make sure this works properly with threads.

=item *

Improve regex matching for substitution variables in SQL statements so
they handle quoting and comments.

=item *

Additional SQL storage options, e.g. SQL::Catalog (store in a database -
should be able to keep SQL in a different database from the app data),
Class::Phrasebook::SQL (store in XML).

=back

=head1 WARNINGS

You must call $dblbn->disconnect explicitly before your program terminates.

This module uses strict throughout.  There is one notable side-effect;
if you have a scalar value in a hash element:

    $data->{name} = "John"

and you run a multi-row SELECT with the same field as a target:

    select* name,
            department
    from    EMPLOYEE

then you are likely to get an error like this:

    Can't use string ("John") as an ARRAY ref while "strict refs"
    in use at .../DBIx/Librarian/Statement/SelectMany.pm line XXX.

This is because it is trying to write values into

    $data->{name}[0]
    $data->{name}[1]
    etc.

Recommended syntax for multi-row, multi-column SELECTs is:

    select* name "employee.name",
            department "employee.dept"
    from    EMPLOYEE

so then you can access the information via

    $data->{employee}[0]->{name}
    $data->{employee}[0]->{dept}
    $data->{employee}[1]->{name}
    etc.

=head1 METHODS

=cut

use DBI;
use Carp;

use Log::Channel;

{
    my $initlog = new Log::Channel ("init");
    sub initlog { $initlog->(@_) }

    my $execlog = new Log::Channel ("exec");
    sub execlog { $execlog->(@_) }
}

my %select_mode = (
		   "*"	=> "zero_or_more",
		   "?"	=> "zero_or_one",
		   "1"	=> "exactly_one",
		   ""	=> "zero_or_more",
		  );

# defaults
my %parameters = (
		  "ARCHIVER" => undef,
		  "LIB"	=> undef,
		  "EXTENSION" => "sql",
		  "AUTOCOMMIT" => 1,
		  "ALLARRAYS" => 0,
		  "DBH" => undef,
		  "DBI_DSN" => undef,
		  "DBI_USER" => undef,
		  "DBI_PASS" => undef,
		  "LONGREADLEN" => 10000,
		  "MAXSELECTROWS" => 1000,
		 );

=item B<new>

  my $dblbn = new DBIx::Librarian({ name => "value" ... });

Supported Librarian parameters:

  ARCHIVER    Reference to class responsible for caching SQL statements.
              Default is Data::Library::OnePerFile.

  LIB         If set, passed through to archiver

  EXTENSION   If set, passed through to archiver

  AUTOCOMMIT  If set, will commit() upon completion of all the SQL
              statements in a tag (not after each statement).
              If not set, the application must call commit() directly.
              Default is set.

  ALLARRAYS   If set, all bind and direct substition variables will
              be obtained from element 0 of the named array, rather
              than from scalars.  Default is off.

  DBH         If set, Librarian will use this database handle and
              will not open one itself.

  DBI_DSN     passed directly to DBI::connect
  DBI_USER    passed directly to DBI::connect
  DBI_PASS    passed directly to DBI::connect

  LONGREADLEN passed through to "LongReadLen" DBI parameter.
              Defaults to 10000.

  MAXSELECTROWS  Set to a numeric value.  Limits the number of rows returned
              by a SELECT call.  Defaults to 1000.

=cut

sub new {
    my ($proto, $config) = @_;
    my $class = ref ($proto) || $proto;

    my $self  = $config || {};

    bless ($self, $class);

    $self->_init;

    return $self;
}


sub _init {
    my ($self) = shift;

    # verify input params and set defaults
    # dies on any unknown parameter
    # fills in the default for anything that is not provided

    foreach my $key (keys %$self) {
	if (!exists $parameters{$key}) {
	    croak "Undefined Librarian parameter $key";
	}
    }

    foreach my $key (keys %parameters) {
	$self->{$key} = $parameters{$key} unless defined $self->{$key};
    }

    if (! defined $self->{DBH}) {
	$self->_connect;
    }

    $self->_init_archiver;
}


sub _init_archiver {
    my ($self) = shift;

    my $archiver = $self->{ARCHIVER};
    my $config = {};
    $config->{LIB} = $self->{LIB} if $self->{LIB};
    $config->{EXTENSION} = $self->{EXTENSION} if $self->{EXTENSION};

    if (!$archiver) {
	# use default archiver

	$archiver = new Data::Library::OnePerFile($config);
    }

    $self->{SQL} = $archiver;
}


sub _connect {
    my ($self) = shift;

    initlog sprintf ("CONNECTING to %s as %s\n",
		     $self->{DBI_DSN} || $ENV{DBI_DSN},
		     $self->{DBI_USER} || $ENV{DBI_USER} || "(none)");

    my $dbh = DBI->connect (
			    $self->{DBI_DSN},
			    $self->{DBI_USER},
			    $self->{DBI_PASS},
			    {
			     RaiseError => 0,
			     PrintError => 0,
			     AutoCommit => 0,
			    }
			   );

    if (!$dbh) {
	croak $DBI::errstr;
    }

    $dbh->{LongReadLen} = $self->{LONGREADLEN};
    $dbh->{LongTruncOk} = 1;

    $self->{DBH} = $dbh;
}


=item B<prepare>

  $dblbn->prepare(@tag_list);

Retrieves, prepares and caches a list of SQL queries.

=cut

sub prepare {
    my ($self, @tags) = @_;

    foreach my $tag (@tags) {
	if (! $self->{SQL}->lookup($tag)) {
	    $self->_prepare($tag);
	}
    }
}


=item B<can>

  $dblbn->can("label");

Returns true if a valid SQL block exists for tag "label".  Side effect is
that the SQL is prepared for later execution.

=cut

sub can {
    my ($self, $tag) = @_;

    return 1 if $self->{SQL}->lookup($tag);

    eval { $self->_prepare($tag) };
    return 1 if $self->{SQL}->lookup($tag);

    return;
}




=item B<execute>

  $dblbn->execute("label", $data);

$data is assumed to be a hash reference.  Inputs for bind variables will
be obtained from $data.  SELECT results will be written back to $data.

The SQL block is obtained from the repository specified above.

An array of two values is returned:
  Total number of rows affected by all SQL statements (including SELECTs)
  Reference to a list of the individual rowcounts for each statement

May abort for various reasons, primarily Oracle errors.  Will abort
if a SELECT is attempted without a $data target.

=cut

sub execute {
    my ($self, $tag, $data) = @_;

    if (! $self->is_connected) {
	$self->disconnect;	# clean up
	$self->_connect;
    }

    my $prepped = $self->{SQL}->lookup($tag);
    if (!$prepped) {
	$prepped = $self->_prepare($tag);
    }

    execlog "EXECUTE $tag\n";

    my @rowcounts = $self->_execute($prepped, $data);
    my $totalrows = 0;
    map { $totalrows += $_ } @rowcounts;

    return $totalrows, \@rowcounts;
}


sub _prepare {
    my ($self, $tag) = @_;

    my $sql = $self->{SQL}->find($tag);
    croak "Unable to find $tag" unless $sql;

    execlog "PREPARE $tag\n";

    my @stmts;

    # for Oracle, support PL/SQL blocks marked by BEGIN...END;
    # a PL/SQL statement block may contain nothing else
    if (($self->{DBH}->{Driver}->{Name} =~ /Oracle/i)
	&& ($sql =~ /^\s*BEGIN/))
    {
#	print STDERR "\tOracle PL/SQL block\n" if $self->{TRACE};
	# treat the entire thing as a single statement.
	push @stmts, $sql;
    } else {

	# a SQL statement is identified as a unit
	#    separated from others by whitespace
	#    containing at least one word at the beginning of a line
	#
	# Note that comments are NOT stripped, since the comment syntax
	# varies between databases.  But a bunch of stuff that doesn't
	# look like a SQL statement will be silently ignored, regardless
	# of syntax.

	@stmts =
	  grep { /^\s*\w/ms }
	    grep { !/^\s*$/ }
	      split (/\s*(\n\s*){2,}/, $sql);
    }

    my @preps;

    foreach my $stmt (@stmts) {
	if ($stmt =~ /^include\s+/io) {
	    my ($include) = $stmt =~ /^include\s+(\S+)/o;
	    push @preps, $include;
	    $self->_prepare($include);
	} else {
	    if ($self->{DBH}->{Driver}->{Name} =~ /Oracle/io) {
		$stmt =~ s/--.*//mog;	# strip out Oracle comments
		if ($stmt !~ /^\s*BEGIN/) {
		    $stmt =~ s/\s*;$//mso; # erase trailing semicolon
		}
	    } else {
		$stmt =~ s/\s*;$//mso;	# erase trailing semicolon
		$stmt =~ s/\s*$//mso;	# erase trailing whitespace
	    }

	    my $statement = new DBIx::Librarian::Statement (
							    $self->{DBH},
							    $stmt,
							    MAXSELECTROWS => $self->{MAXSELECTROWS},
							    NAME => $tag,
							   );
	    $statement->{ALLARRAYS} = $self->{ALLARRAYS};
	    push @preps, $statement;
	}
    }

    $self->{SQL}->cache($tag, \@preps);

    return \@preps;
}


sub _execute {
    my ($self, $prep, $data) = @_;

    my @rowcounts;

    my $changes = 0;
    foreach my $stmt_prep (@{$prep}) {
	if (!ref($stmt_prep)) {
	    # found an include
	    push @rowcounts, $self->execute($stmt_prep, $data);
	} else {
	    eval {
		my $rows = $stmt_prep->execute($data);
		push @rowcounts, $rows;
	    };
	    if ($@) {
		if ($self->{AUTOCOMMIT} && $changes) {
		    $self->rollback;
		}
		die $@;
	    }
	    $changes++ unless $stmt_prep->{IS_SELECT};
	}
    }

    if ($self->{AUTOCOMMIT} && $changes) {
#	# there was at least one non-SELECT, so better commit here
	$self->commit;
    }

    return @rowcounts;
}


=item B<commit>

Invokes commit() on the database handle.  Not needed unless
$dblbn->delaycommit() has been called.

=cut

sub commit {
    my ($self) = @_;

    execlog "COMMIT\n";

    $self->{DBH}->commit;
}

=item B<rollback>

Invokes rollback() on the database handle.  Not needed unless
$dblbn->delaycommit() has been called.

=cut

sub rollback {
    my ($self) = @_;

    execlog "ROLLBACK\n";

    $self->{DBH}->rollback;
}

=item B<autocommit>

Sets the AUTOCOMMIT flag.  Once set, explicit commit and rollback
are not needed.

=cut

sub autocommit {
    my ($self) = @_;

    $self->{AUTOCOMMIT} = 1;
}

=item B<delaycommit>

Clears the AUTOCOMMIT flag.  Explicit commit and rollback will be
needed to apply changes to the database.

=cut

sub delaycommit {
    my ($self) = @_;

    $self->{AUTOCOMMIT} = 0;
}

=item B<disconnect>

  $dblbn->disconnect;

Disconnect from the database.  Database handle and any active statements
are discarded.

=cut

sub disconnect {
    my ($self) = @_;

    initlog sprintf ("DISCONNECT %s\n",
		     $self->{DBI_DSN} || $ENV{DBI_DSN});

    $self->{DBH}->disconnect if $self->{DBH};
    undef $self->{DBH};
    $self->{SQL}->reset;
}

=item B<is_connected>

  $dblbn->is_connected;

Returns boolean indicator whether the database connection is active.  This
depends on the $dbh->{Active} flag set by DBI, which is driver-specific.

=cut

sub is_connected {
    my ($self) = @_;

    return 1 if $self->{DBH} && $self->{DBH}->ping;
}

sub DESTROY {
    my ($self) = @_;

    $self->disconnect if $self->is_connected;
}

1;

=head1 LOGGING

Declares two log channels using Log::Channel, "init" and "exec".
Connect and disconnect events are logged to the init channel,
query execution (prepare, execute, commit, rollback) to exec.

See also the channels for DBIx::Librarian::Statement logging.

=head1 AUTHOR

Jason W. May <jmay@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2001-2003 Jason W. May.  All rights reserved.
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 TEST SUITE

Under development.

=head1 SEE ALSO

  Class:Phrasebook::SQL
  Ima::DBI
  SQL::Catalog
  DBIx::SearchProfiles
  DBIx::Abstract
  DBIx::Recordset
  Tie::DBI

  Relevant links stolen from SQL::Catalog documentation:
    http://perlmonks.org/index.pl?node_id=96268&lastnode_id=96273
    http://perlmonks.org/index.pl?node=Leashing%20DBI&lastnode_id=96268

=cut
