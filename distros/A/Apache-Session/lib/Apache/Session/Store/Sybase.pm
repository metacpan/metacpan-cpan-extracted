#############################################################################
#
# Apache::Session::Store::Sybase
# Apache persistent user sessions in a DBI::Sybase database
#
# Copyright(c) 2000, 2004 Jeffrey William Baker (jwbaker@acm.org), Mark Landry (mdlandry@lincoln.midcoast.com), and Chris Winters (chris@cwinters.com)
#
# With modifications from earlier version of Apache::Session::DBI::Sybase
#   from Mark Landry (mdlandry@lincoln.midcoast.com)
# 
# Modified to work with Apache::Session v 1.5+ by Chris Winters (chris@cwinters.com)
#
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Store::Sybase;

use strict;
use vars qw( @ISA $VERSION );

use Apache::Session::Store::DBI;

@ISA     = qw( Apache::Session::Store::DBI );
$VERSION = '1.01';

$Apache::Session::Store::Sybase::DataSource = undef;
$Apache::Session::Store::Sybase::UserName   = undef;
$Apache::Session::Store::Sybase::Password   = undef;

sub connection {
    my $self    = shift;
    my $session = shift;
    
    return if ( defined $self->{dbh} );

    if ( exists $session->{args}->{Handle} ) {
        $self->{dbh} = $session->{args}->{Handle};
        $self->{commit} = $session->{args}->{Commit};
    }
	else {
	  my $datasource = $session->{args}->{DataSource} || 
           $Apache::Session::Store::Sybase::DataSource;
	  my $username = $session->{args}->{UserName} ||
           $Apache::Session::Store::Sybase::UserName;
	  my $password = $session->{args}->{Password} ||
           $Apache::Session::Store::Sybase::Password;
        
	  $self->{dbh} = DBI->connect(
		  $datasource,
          $username,
          $password,
          { RaiseError => 1, AutoCommit => 0 }
      ) || die $DBI::errstr;

    
	  # If we open the connection, we close the connection
	  $self->{disconnect} = 1;
	}
    
    # the programmer has to tell us what commit policy to use;
	# note that this should take effect even if the programmer
	# passes us a handle
    $self->{commit} = $session->{args}->{Commit};

	# sets the variable @@textsize to the default, which
	# should be 32K; to test, do this from a isql/sqsh session:
	#
	# > set textsize 0
	# > go
	# > select @@textsize
	# > go
	# 
	# You should see something like:
    # : 
	# :  -----------
    # :        32768
	# 
	# Note that you can also pass an argument ('textsize') for a 
	# larger/smaller text size
	my $textsize = $session->{args}->{textsize} || '0';
	$self->{dbh}->do( "set textsize $textsize" );

}

# Both insert() and update() are modifications to
# Apache::Session::Store::DBI.

# Sybase cannot use placeholders for IMAGE/TEXT field types so you
# must pass the data directly in the SQL rather than using bound
# parameters. Naturally, this negates any usefulness of the
# 'prepare_cached' method used in Apache::Session::Store::DBI, so we
# use a more straightforward sequence to prepare/execute here.

# Also, if you use this storage mechanism, you must also use the
# serializer that puts the data structure into a format that you can
# put directly into the SQL statement (e.g., '0xblahblahblah')

sub insert {
    my $self    = shift;
    my $session = shift;
 
    $self->connection( $session );

    local $self->{dbh}->{RaiseError} = 1;

	my $sth = $self->{dbh}->prepare( qq{ 
                 INSERT INTO sessions (id, a_session) VALUES ( }.$self->{dbh}->quote($session->{data}->{_session_id}).qq{, }.$self->{dbh}->quote($session->{serialized}).qq{ ) } );

    $sth->execute( );
}


sub update {
    my $self    = shift;
    my $session = shift;
 
    $self->connection( $session );

    local $self->{dbh}->{RaiseError} = 1;

	my $sth = $self->{dbh}->prepare( qq{ 
                 UPDATE sessions SET a_session = }.$self->{dbh}->quote($session->{serialized}).qq{ WHERE id = }.$self->{dbh}->quote($session->{data}->{_session_id}) );

    $sth->execute( );
}

sub materialize {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    $self->{materialize_sth} =
            $self->{dbh}->prepare(qq{
                SELECT a_session FROM sessions WHERE id = }.$self->{dbh}->quote(
$session->{data}->{_session_id}));

    $self->{materialize_sth}->execute;

    my $results = $self->{materialize_sth}->fetchrow_arrayref;

    if (!(defined $results)) {
        die "Object does not exist in the data store";
    }

    $self->{materialize_sth}->finish;

    $session->{serialized} = $results->[0];
}

sub remove {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;

    $self->{remove_sth} =
            $self->{dbh}->prepare_cached(qq{
                DELETE FROM sessions WHERE id = }.$self->{dbh}->quote($session->{data}->{_session_id}));

    $self->{remove_sth}->execute;
    $self->{remove_sth}->finish;
}

sub DESTROY {
    my $self = shift;

    if ( $self->{commit} ) {
        $self->{dbh}->commit;
    }
    
    if ( $self->{disconnect} ) {
        $self->{dbh}->disconnect;
    }
}

1;

=pod

=head1 NAME

Apache::Session::Store::Sybase - Store persistent data in a Sybase database

=head1 SYNOPSIS

 use Apache::Session::Store::Sybase;

 my $store = new Apache::Session::Store::MySQL;

 $store->insert( $ref );
 $store->update( $ref );
 $store->materialize( $ref );
 $store->remove( $ref );

=head1 DESCRIPTION

Apache::Session::Store::Sybase fulfills the storage interface of
Apache::Session.  Session data is stored in a Sybase database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table 
called 'sessions':

 id        CHAR(32)     # or however long your session IDs are.
 a_session IMAGE

To create this schema, you can execute this command using the isql or
sqsh programs:

 CREATE TABLE sessions (
    id         CHAR(32) not null primary key,
    a_session  TEXT
 )
 go

If you use some other command, ensure that there is a unique index on the
id column of the table

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are:

=over 4

=item DataSource

=item UserName

=item Password

=back

Example:

 tie %hash, 'Apache::Session::Sybase', $id, {
     DataSource => 'dbi:Sybase:database=db;server=server',
     UserName   => 'database_user',
     Password   => 'K00l',
     Commit     => 1,
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::Sybase', $id, {
     Handle => $dbh
 };

Additional arguments you can pass to the backing store are:

=over 4

=item Commit - whether we should commit any changes; if you pass in
an already-open database handle that has AutoCommit set to a true
value, you do not need to set this. If you let
Apache::Session::Store::Sybase create your database, handle, you must
set this to a true value, otherwise, your changes will not be saved

=item textsize - the value we should pass to the 'set textsize '
command that sets the max size of the IMAGE field. Default is 32K (at
least in Sybase ASE 11.9.2).

=back

=head1 AUTHOR

This module was based on L<Apache::Session::Store::Oracle> which was
written by Jeffrey William Baker <jwbaker@acm.org>; it was modified by
Chris Winters <chris@cwinters.com> to work with Apache::Session 1.5+
with changes from earlier version of Apache::Session::DBI::Sybase from
Mark Landry <mdlandry@lincoln.midcoast.com>.

=head1 SEE ALSO

L<Apache::Session>

=cut
