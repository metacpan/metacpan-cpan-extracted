#
# Data::Shark::DBI.pm
#
# Copyright (C) 2007 William Walz. All Rights Reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Data::Shark::DBI;

use version; our $VERSION = qv('2.1');

use strict;
use base qw( Exporter );

use DBI;

our @EXPORT      = qw( );
our @EXPORT_OK   = qw( );
our %EXPORT_TAGS = ( );

# private
my %desc_hash = ();

# constructor for DBI
sub new {

    my ( $class, $dsn, $user, $password, $options ) = @_;

    my $dbh;
    my $errstr;
    my $own;

    # check for dbh handle passed as first argument
    if (ref $dsn) {
        $dbh = $dsn;
        $own = 0;
    } else {
        $dbh    = DBI->connect($dsn, $user, $password, $options);
        $errstr = $DBI::errstr;
        $own    = 1;
    }
    
    # 
    # create the object
    my $self = {
	'dsn'          => $dsn,
	'user'         => $user,
	'pass'         => $password,
	'dbh'          => $dbh,
	'own'          => $own,
        'errstr'       => $errstr,
	'log'          => undef,
	'log_fetch'    => '0', # don't log fetched values by default
	'log_fetchall' => '0', # don't log fetchall values by default
    };

    bless ( $self, $class );

    return( $self );
}
sub DESTROY {
    my ($self) = @_;
    # disconnect if we have a handle and its ours;
    $self->{'dbh'}->disconnect() if $self->{'dbh'} && $self->{'own'}; 
}

#-------------------------------------------------------------------------
#
# Data::Shark::DBI DBI FUNCTIONS
#
#-------------------------------------------------------------------------

#
#  Setup Log Function
#
sub db_log {
    my ($self, $logfunc, $log_fetch, $log_fetchall) = @_;

    $log_fetch     ||= '0';
    $log_fetchall  ||= '0';

    $self->{'log'}          = $logfunc;
    $self->{'log_fetch'}    = $log_fetch;
    $self->{'log_fetchall'} = $log_fetchall;
}
#
#  Prepare SQL
#
sub db_prep {
    my ($self, $sql) = @_;

    $self->{'log'}->('prepare: ' . $sql) if $self->{'log'};
    # prepare
    my $sth = $self->{'dbh'}->prepare($sql) or ($self->{'log'} && $self->{'log'}->('FAILED: prepare ' . $DBI::errstr));
    return $sth;
}
#
#  Execute SQL
#
sub db_exec {
    my ($self, $sth, @args) = @_;

    $self->{'log'}->('execute: (' . (@args > 0 ? join(',', @args) : '') . ')') if $self->{'log'};
    my $c = 1;
    foreach my $arg (@args) {
      ref($arg)?
        $sth->bind_param_inout($c++,$arg,256)
        :
        $sth->bind_param($c++,$arg);
    }
    $sth->execute() or ($self->{'log'} && $self->{'log'}->('FAILED: execute: (' . (@args > 0 ? join(',', @args) : '') . ') ' .  $DBI::errstr));
}
#
#  Prepare/Execute SQL
#
sub db_sql {
    my ($self, $sql, @args) = @_;

    $self->{'log'}->('prepare: ' . $sql) if $self->{'log'};
    # prepare
    my $sth = $self->{'dbh'}->prepare($sql) or ($self->{'log'} && $self->{'log'}->('FAILED: prepare ' . $DBI::errstr));
    if ($sth) {
	$self->{'log'}->('execute: (' . (@args > 0 ? join(',', @args) : '') . ')') if $self->{'log'};
        my $c = 1;
        foreach my $arg (@args) {
          ref($arg) ?
            $sth->bind_param_inout($c++,$arg,256)
            :
            $sth->bind_param($c++,$arg);
        }
	$sth->execute() or do {
	    $self->{'log'}->('FAILED: execute: (' .
			     join(',', @args) . ') ' .
			     $DBI::errstr) if $self->{'log'};
	    $self->{'errstr'} = 'FAILED: execute: (' .
		join(',', @args) . ') ' .
		    $DBI::errstr;
	    $sth->finish();
	    undef $sth;
	};
    }

    return $sth;
}
#
#  Fetch
#
sub db_fetch {
    my ($self, $sth) = @_;
    
    my @rows;

    @rows = $sth->fetchrow() if $sth;

    $self->{'log'}->('fetch: (' .
      join(',', @rows) .')') if $sth && $self->{'log'} && $self->{'log_fetchall'};

    return @rows;
}
#
#  Fetch Array Ref
#
sub db_fetch_arrayref {
    my ($self, $sth) = @_;

    my $rows;

    $rows = $sth->fetchrow_arrayref() if $sth;

    $self->{'log'}->('fetch_arrayref: (' .
      join(',', @{$rows}) .')') if $sth && $self->{'log'} && $self->{'log_fetchall'};

    return $rows;
}
#
#  Fetch All
#
sub db_fetchall {
    my ($self, $sth) = @_;

    my $allrows = $sth->fetchall_arrayref() if $sth;

    if ($sth && $self->{'log'} && $self->{'log_fetch'}) {
      if ($allrows) {
        foreach my $row (@{$allrows}) {
          $self->{'log'}->('fetch: (' .  join(',', @{$row}) .')');
        }
      } else {
          $self->{'log'}->('fetch: ()');
      }
    }

    return $allrows;
}
#
#  Fetch All
#
sub db_exec_fetchall_args {
    my ($self, $sql, @args) = @_;

    if ($self->{'log'}) {
      $self->{'log'}->('prepare: ' . $sql);
      $self->{'log'}->('execute: (' . (@args > 0 ? join(',', @args) : '') . ')');
    }

    my $rows = $self->{'dbh'}->selectall_arrayref($sql, {Slice => {}}, @args);

    if ($self->{'log'} && $self->{'log_fetch'}) {
      if ($rows) {
        foreach my $row (@{$rows}) {
          $self->{'log'}->('fetch: (' .  join(',', values %{$row}) .')');
        }
      } else {
          $self->{'log'}->('fetch: ()');
      }
    }

    return $rows;
}
#
#  Rows
#
sub db_rows {
    my ($self, $sth) = @_;

    return $sth->rows() if $sth;
}
#
#  Finish
#
sub db_done {
    my ($self, $sth) = @_;

    $sth->finish() if $sth;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Data::Shark::DBI -- Database Functions

=head1 DESCRIPTION

This module contains some DBI wrappers for the Data::Shark.  By using the
simple wrappers a single point of database access and error/status logging
can be achieved, along with code size reduction.  Native DBI/DBD functions
can still be used on the object.

Example:

  #
  # Construct DB object and connect
  #
  my $dsn = "dbi:Pg:dbname=$dbmain";
  my $db  = Data::Shark::DBI->new($dsn, $user, $pass,{ AutoCommit => 1 });
  # setup logging function
  $db->db_log(sub {my ($data) = @_;mylog('SQL',$data);});


Example:

  #
  #  Grab Orders
  #
  $sth = $db->db_sql(q{
      SELECT custnum,custname,address,phone,suburb,ubd,comments,
             lastorder_num,lastorder_date,bad_cust,
             discount,deliv_charge
        FROM customers
       WHERE custnum = ?
     },$cust_id);
  @d = $db->db_fetch($sth);
  $db->db_done($sth);

=head1 OBJECT INTERFACE

=head2 new ( $dsn, $user, $password, $options ) or new ( $dbi_handle )

New creates the DB object.  It either returns the object on
successful creation or undef upon failure.  $! is the
error code if any.  The object contains the following hash
members:

=over 4

=item *
dsn		datasource string passed to new

=item *
user		username passed to new

=item *
pass		password passed to new

=item *
dbh		the newly created database handle (DBI) or the passed handle

=item *
log		a pointer the logging function

=item *
log_fetch	flag to indicate if fetched values should be joined with a comma and passed to the logging function.  The default is 0 

=item *
log_fetchall	flag to indicate if fetch all values should be joined with a comma and passed to the logging function.  The default is 0 

=back

=head1 DATABASE INTERACTION OBJECT INTERFACE

=head2 db_sql ( $sql, @args )

This function does a prepare on the passed sql statement and then
executes the statement passing the args array.  The statement and
execute call along witht the passed args are logged via the logging
function.  A DBI statement handle is returned.

If the prepare fails then an error is logged and no statement handle
is returned.

If the execute fails then an error is logged and the statement handle
is cleaned up, and nothing is returned.

=head2 db_fetch ( $sth )

This function executes fetchrow on the passed statement handle.  If
$self->{'log_fetch'} is non zero then the values returned are 
logged via the logging function.  The results array is returned.

=head2 db_fetch_arrayref ( $sth )

This function executes fetchrow_arrayref on the passed statement
handle.  If $self->{'log_fetch'} is non zero then the values
returned are logged via the logging function.  The results array
reference is returned.

=head2 db_fetchall ( $sth )

This function executes fetchall_arrayref on the passed statement handle.
If $self->{'log_fetchall'} is non zero then the values returned are
logged via the logging function.  The results array reference is returned.

=head2 db_exec_fetchall_args ( $sql, @args )

This function executes the DBI function as follows: 

  selectall_arrayref($sql, {Slice => {}}, @args);

This utility method combines "prepare", "execute" and "fetchall_arrayref"
into a single call. It returns a reference to an array containing a
reference to a hash for each row of data fetched.

The $sql parameter can be a previously prepared statement handle, in which
case the "prepare" is skipped. This is recommended if the statement is
going to be executed many times.

If $self->{'log_fetchall'} is non zero then the values returned are
logged via the logging function.

=head2 db_done ( $sth )

This function executes finish on the statement handle.  No logging
occurs.

=head2 db_log ( &logfunction, [$log_fetch] )

This function sets the logging function to be called for logging
operations.  The log function is passed the string to log. If the
log_fetch argument is passed and equals 1 then the fetched values
from any sql statements will be present in the log.

=head2 db_rows ( $sth )

This function executes rows on the statement handle and returns the
result.

=head2 db_prep ( $sql )

This function only executes the prepare function on the sql statement
and returns the DBI statement handle.  The prepare is logged.  If the
prepare fails then nothing is returned.

=head2 db_exec ( $sth, @args )

This function executes the statement handle and passes the args array.
The result is logged.  If the execute fails then an error is logged.

=head1 SEE ALSO

L<perl>

L<Data::Shark>

L<DBI>

=head1 AUTHORS

    William Walz (Jack)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 William Walz. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
