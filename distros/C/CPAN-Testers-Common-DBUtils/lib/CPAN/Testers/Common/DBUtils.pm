package CPAN::Testers::Common::DBUtils;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '0.11';

=head1 NAME

CPAN::Testers::Common::DBUtils - Basic Database Wrapper

=head1 SYNOPSIS

  use CPAN::Testers::Common::DBUtils;

  my $dbx = CPAN::Testers::Common::DBUtils->new(
                driver      => 'mysql',
                database    => 'testdb');

  sub errors { print STDERR "Error: $_[0], sql=$_[1]\n" }
  my $dbi = CPAN::Testers::Common::DBUtils->new(
                driver  => 'CSV',
                dbfile  => '/var/www/mysite/db
                errsub  => \&errors);

  my @arr = $dbi->get_query('array',$sql);
  my @arr = $dbi->get_query('array',$sql,$id);
  my @arr = $dbi->get_query('hash', $sql,$id);

  my $id = $dbi->id_query($sql,$id,$name);
  $dbi->do_query($sql,$id);

  $dbi->do_rollback();  # where AutoCommit is disabled
  $dbi->do_commit();    # where AutoCommit is disabled

  # array iterator
  my $next = $dbi->iterator('array',$sql);
  my $row = $next->();
  my $id = $row->[0];

  # hash iterator
  my $next = $dbi->iterator('hash',$sql);
  my $row = $next->();
  my $id = $row->{id};

  $value = $dbi->quote($value);

=head1 DESCRIPTION

The DBUtils package is a wrapper around the database interface layer, providing
a collection of methods to access and alter the data within the database, which
handle any errors and abstracts these commonly called routines away from the
calling program.

Known supported drivers:

  MySQL     (database)
  SQLite    (database)
  CSV       (dbfile)
  ODBC      (driver)

The keys in braces above, indicate how the name/location of the data store is
passed to the wrapper and thus added to the connection string.

=cut

# -------------------------------------
# Library Modules

use Carp;
use DBI;

use base qw(Class::Accessor::Fast);

# -------------------------------------
# The Public Interface Subs

=head2 CONSTRUCTOR

=over 4

=item new()

The Constructor method can be called with an anonymous hash,
listing the values to be used to connect to and handle the database.

Values in the hash can be

  driver (*)
  database (+)
  dbfile (+)
  dbhost
  dbport
  dbuser
  dbpass
  errsub
  AutoCommit

(*) These entries MUST exist in the hash.
(+) At least ONE of these must exist in the hash, and depend upon the driver.

Note that 'dbfile' is for use with a flat file database, such as DBD::CSV.

By default the errors are handle via croak(), however if you pass a subroutine
reference that will be called instead. Parameters passed to the error
subroutine are the error string, the SQL string and the list of arguments given.

AutoCommit is on by default, unless you explicitly pass 'AutoCommit => 0'.

=back

=cut

sub new {
    my ($self, %hash) = @_;

    # check we've got our mandatory fields
    croak("$self needs a driver!")      unless($hash{driver});
    croak("$self needs a database/file!")
            unless($hash{database} || $hash{dbfile});

    # create an attributes hash
    my $dbv = {
        'driver'     => $hash{driver},
        'database'   => $hash{database},
        'dbfile'     => $hash{dbfile},
        'dbhost'     => $hash{dbhost},
        'dbport'     => $hash{dbport},
        'dbuser'     => $hash{dbuser},
        'dbpass'     => $hash{dbpass},
        'errsub'     => $hash{errsub} || \&_errsub,
        'AutoCommit' => defined $hash{AutoCommit} ? $hash{AutoCommit} : 1,
    };

    # create the object
    bless $dbv, $self;
    return $dbv;
}

=head2 PUBLIC INTERFACE METHODS

=over 4

=item get_query(type,sql,<list>)

  type - 'array' or 'hash'
  sql - SQL statement
  <list> - optional additional values to be inserted into SQL placeholders

This method performs a SELECT statement and returns an array of the returned
rows. Each column within the row is then accessed as an array or hash as
specified by 'type'.

=cut

sub get_query {
    my ($dbv,$type,$sql,@args) = @_;
    return ()   unless($sql);

    # if the object doesn't contain a reference to a dbh
    # object then we need to connect to the database
    $dbv = _db_connect($dbv) if not $dbv->{dbh};

    # prepare the sql statement for executing
    my $sth;
    eval { $sth = $dbv->{dbh}->prepare($sql) };
    if($@ || !$sth) {
        $dbv->{errsub}->($dbv->{dbh}->errstr,$sql,@args);
        return ();
    }

    # execute the SQL using any values sent to the function
    # to be placed in the sql
    my $res;
    eval { $res = $sth->execute(@args); };
    if($@ || !$res) {
        $dbv->{errsub}->($sth->errstr,$sql,@args);
        return ();
    }

    my @result;
    # grab the data in the right way
    if ( $type eq 'array' ) {
        while ( my $row = $sth->fetchrow_arrayref() ) {
            push @result, [@{$row}];
        }
    } else {
        while ( my $row = $sth->fetchrow_hashref() ) {
            push @result, $row;
        }
    }

    # finish with our statement handle
    $sth->finish;
    # return the found datastructure
    return @result;
}

=item iterator(type,sql,<list>)

  type - 'array' or 'hash'
  sql - SQL statement
  <list> - optional additional values to be inserted into SQL placeholders

This method is used to call a SELECT statement a row at a time, via a closure.
Returns a subroutine reference which can then be used to obtain each row as a
array reference or hash reference. Finally returns 'undef' when no more rows
can be returned.

=cut

sub iterator {
    my ($dbv,$type,$sql,@args) = @_;
    return  unless($sql);

    # if the object doesn't contain a reference to a dbh
    # object then we need to connect to the database
    $dbv = _db_connect($dbv) if not $dbv->{dbh};

    # prepare the sql statement for executing
    my $sth;
    eval { $sth = $dbv->{dbh}->prepare($sql); };
    if($@ || !$sth) {
        $dbv->{errsub}->($dbv->{dbh}->errstr,$sql,@args);
        return;
    }

    # execute the SQL using any values sent to the function
    # to be placed in the sql
    my $res;
    eval { $res = $sth->execute(@args); };
    if($@ || !$res) {
        $dbv->{errsub}->($sth->errstr,$sql,@args);
        return;
    }

    # grab the data in the right way
    if ( $type eq 'array' ) {
        return sub {
            if ( my $row = $sth->fetchrow_arrayref() ) { return $row; }
            else { $sth->finish; return; }
        }
    } else {
        return sub {
            if ( my $row = $sth->fetchrow_hashref() ) { return $row; }
            else { $sth->finish; return; }
        }
    }
}

=item do_query(sql,<list>)

  sql - SQL statement
  <list> - optional additional values to be inserted into SQL placeholders

This method is used to perform an SQL action statement.

=cut

sub do_query {
    my ($dbv,$sql,@args) = @_;
    $dbv->_do_query($sql,0,@args);
}

=item id_query(sql,<list>)

  sql - SQL statement
  <list> - optional additional values to be inserted into SQL placeholders

This method is used to perform an SQL action statement. Commonly used when
performing an INSERT statement, so that it returns the inserted record id.

=cut

sub id_query {
    my ($dbv,$sql,@args) = @_;
    return $dbv->_do_query($sql,1,@args);
}

# _do_query(sql,idrequired,<list>)
#
#  sql - SQL statement
#  idrequired - true if an ID value is required on return
#  <list> - optional additional values to be inserted into SQL placeholders
#
# This method is used to perform an SQL action statement. Commonly used when
# performing an INSERT statement, so that it returns the inserted record id.

sub _do_query {
    my ($dbv,$sql,$idrequired,@args) = @_;
    my $rowid;

    return  unless($sql);

    # if the object doesn't contain a reference to a dbh
    # object then we need to connect to the database
    $dbv = _db_connect($dbv) if not $dbv->{dbh};

    if($idrequired) {
        # prepare the sql statement for executing
        my $sth;
        eval { $sth = $dbv->{dbh}->prepare($sql); };
        if($@ || !$sth) {
            $dbv->{errsub}->($dbv->{dbh}->errstr,$sql,@args);
            return;
        }

        # execute the SQL using any values sent to the function
        # to be placed in the sql
        my $res;
        eval { $res = $sth->execute(@args); };
        if($@ || !$res) {
            $dbv->{errsub}->($sth->errstr,$sql,@args);
            return;
        }

        if($dbv->{driver} =~ /mysql/i) {
            $rowid = $dbv->{dbh}->{mysql_insertid};
        } elsif($dbv->{driver} =~ /pg/i) {
            my ($table) = $sql =~ /INTO\s+(\S+)/;
            $rowid = $dbv->{dbh}->last_insert_id(undef,undef,$table,undef);
        } elsif($dbv->{driver} =~ /sqlite/i) {
            $sth = $dbv->{dbh}->prepare('SELECT last_insert_rowid()');
            $res = $sth->execute();
            my $row;
            $rowid = $row->[0]  if( $row = $sth->fetchrow_arrayref() );
        } else {
            my $row;
            $rowid = $row->[0]  if( $row = $sth->fetchrow_arrayref() );
        }

    } else {
        eval { $dbv->{dbh}->do($sql, undef, @args) };
        if ( $@ ) {
            $dbv->{errsub}->($dbv->{dbh}->errstr,$sql,@args);
            return -1;
        }

        $rowid = 1;     # technically this should be the number of succesful rows
    }

    ## Return the rowid we just used
    return $rowid;
}

=item repeat_query(sql,<list>,[(<arg1>), ... (<argN>)])

  sql - SQL statement
  <list> - values to be inserted into SQL placeholders
  <argX> - arguments to be inserted into placeholders

This method is used to store an SQL action statement, together withe the 
associated arguments. Commonly used with statements where multiple arguments 
sets are applied to the same statement.

=item repeat_queries()

This method performs all stored SQL action statements.

=item repeater(sql,<list ref>)

  sql - SQL statement
  <list ref> - list of values to be inserted into SQL placeholders

This method performs an single SQL action statement, using all the associated 
arguments within the given list reference.

=cut

sub repeat_query {
    my ($dbv,$sql,@args) = @_;
    return  unless($sql && @args);

    # if the object doesn't contain a reference to a dbh
    # object then we need to connect to the database
    $dbv = _db_connect($dbv) if not $dbv->{dbh};

    push @{ $dbv->{repeat}{$sql} }, \@args;
}

sub repeat_queries {
    my $dbv = shift;
    return 0    unless($dbv && $dbv->{repeat});

    my $rows = 0;
    for my $sql (keys %{ $dbv->{repeat} }) {
        $rows += $dbv->repeater($sql,$dbv->{repeat}{$sql});
    }

    $dbv->{repeat} = undef;
    return $rows;
}

sub repeater {
    my ($dbv,$sql,$args) = @_;
    my $rows = 0;

    return $rows    unless($sql);

    # if the object doesn't contain a reference to a dbh
    # object then we need to connect to the database
    $dbv = _db_connect($dbv) if not $dbv->{dbh};

    # prepare the sql statement for executing
    my $sth;
    eval { $sth = $dbv->{dbh}->prepare($sql); };
    if($@ || !$sth) {
        $dbv->{errsub}->($dbv->{dbh}->errstr,$sql,@{$args->[0]});
        return $rows;
    }

    for my $arg (@$args) {
        # execute the SQL using any values sent to the function
        # to be placed in the sql
        my $res;
        eval { $res = $sth->execute(@$arg); };
        if($@ || !$res) {
            $dbv->{errsub}->($sth->errstr,$sql,@$args);
            next;
        }

        $rows++;
    }

    return $rows;
}

=item do_commit()

Performs a commit on the transaction where AutoCommit is disabled.

=cut

sub do_commit {
    my $dbv  = shift;
    $dbv->{dbh}->commit if($dbv->{dbh});
}

=item do_rollback()

Performs a rollback on the transaction where AutoCommit is disabled.

=cut

sub do_rollback {
    my $dbv  = shift;
    $dbv->{dbh}->rollback if($dbv->{dbh});
}

=item quote(string)

  string - string to be quoted

This method performs a DBI quote operation, which will quote a string
according to the SQL rules.

=cut

sub quote {
    my $dbv  = shift;
    return  unless($_[0]);

    # Cant quote with DBD::CSV
    return $_[0]    if($dbv->{driver} =~ /csv/i);

    # if the object doesnt contain a reference to a dbh object
    # then we need to connect to the database
    $dbv = _db_connect($dbv) if not $dbv->{dbh};

    $dbv->{dbh}->quote($_[0]);
}

# -------------------------------------
# The Accessors

=item Accessor Methods

The following accessor methods are available:

=over 4

=item * driver

=item * database

=item * dbfile

=item * dbhost

=item * dbport

=item * dbuser

=item * dbpass

=back

All methods can be called to return the current value of the associated
object variable. Note that these are only meant to be used as read-only
methods.

=cut

__PACKAGE__->mk_accessors(qw(driver database dbfile dbhost dbport dbuser dbpass));

# -------------------------------------
# The Private Subs
# These modules should not have to be called from outside this module

sub _db_connect {
    my $dbv  = shift;

    my $dsn =   'dbi:' . $dbv->{driver};
    my %options = (
        RaiseError => 1,
        AutoCommit => $dbv->{AutoCommit},
    );

    if($dbv->{driver} =~ /ODBC/) {
        # all the info is in the Data Source repository

    } elsif($dbv->{driver} =~ /SQLite/i) {
        $dsn .=     ':dbname='   . $dbv->{database} if $dbv->{database};
        $dsn .=     ';host='     . $dbv->{dbhost}   if $dbv->{dbhost};
        $dsn .=     ';port='     . $dbv->{dbport}   if $dbv->{dbport};

        $options{sqlite_handle_binary_nulls} = 1;

    } else {
        $dsn .=     ':f_dir='    . $dbv->{dbfile}   if $dbv->{dbfile};
        $dsn .=     ':database=' . $dbv->{database} if $dbv->{database};
        $dsn .=     ';host='     . $dbv->{dbhost}   if $dbv->{dbhost};
        $dsn .=     ';port='     . $dbv->{dbport}   if $dbv->{dbport};
    }

    eval {
        $dbv->{dbh} = DBI->connect($dsn, $dbv->{dbuser}, $dbv->{dbpass}, \%options);
    };

    croak("Cannot connect to DB [$dsn]: $@")    if($@);
    return $dbv;
}

sub DESTROY {
    my $dbv = shift;
#   $dbv->{dbh}->commit     if defined $dbv->{dbh};
    $dbv->{dbh}->disconnect if defined $dbv->{dbh};
}

sub _errsub {
    my ($err,$sql,@args) = @_;
    croak("err=$err, sql=[$sql], args[".join(",",map{$_ || ''} @args)."]");
}

1;

__END__

=back

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Statistics>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
