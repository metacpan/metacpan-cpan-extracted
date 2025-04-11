package Apache::Session::Browseable::Store::Cassandra;

use strict;

use Apache::Session::Store::DBI;
use Apache::Session::Browseable::Store::DBI;
use Apache::Session::Browseable::Store::Cassandra;

our @ISA     = qw(Apache::Session::Browseable::Store::DBI);
our $VERSION = '1.3.13';

our $DataSource = undef;
our $UserName   = undef;
our $Password   = undef;

sub connection {
    my $self    = shift;
    my $session = shift;

    return if ( defined $self->{dbh} );

    if ( exists $session->{args}->{Handle} ) {
        $self->{dbh} = $session->{args}->{Handle};
        return;
    }

    my $datasource = $session->{args}->{DataSource}
      || $DataSource;
    my $username = $session->{args}->{UserName}
      || $UserName;
    my $password = $session->{args}->{Password}
      || $Password;

    $self->{dbh} =
      DBI->connect( $datasource, $username, $password, { RaiseError => 1 } )
      || die $DBI::errstr;

    #If we open the connection, we close the connection
    $self->{disconnect} = 1;
}

sub materialize {
    my $self    = shift;
    my $session = shift;

    $self->connection($session);

    local $self->{dbh}->{RaiseError} = 1;
    local $self->{dbh}->{LongReadLen} =
      $session->{args}->{LongReadLen} || 8 * 2**10;

    if ( !defined $self->{materialize_sth} ) {
        $self->{materialize_sth} = $self->{dbh}->prepare_cached(
            qq{
                SELECT a_session FROM sessions WHERE id = ? FOR UPDATE}
        );
    }

    $self->{materialize_sth}->bind_param( 1, $session->{data}->{_session_id} );
    $self->{materialize_sth}->execute;

    my $results = $self->{materialize_sth}->fetchrow_arrayref;

    if ( !( defined $results ) ) {
        die "Object does not exist in the data store";
    }

    $self->{materialize_sth}->finish;

    $session->{serialized} = $results->[0];
}

sub DESTROY {
    my $self = shift;

    if ( $self->{disconnect} ) {
        $self->{dbh}->disconnect;
    }
}

1;

=pod

=head1 NAME

Apache::Session::Browseable::Store::Cassandra - Store persistent data in a Cassandra database

=head1 SYNOPSIS

  use Apache::Session::Browseable::Store::Cassandra;
  
  my $store = new Apache::Session::Browseable::Store::Cassandra;
  
  $store->insert($ref);
  $store->update($ref);
  $store->materialize($ref);
  $store->remove($ref);

=head1 DESCRIPTION

Apache::Session::Browseable::Store::Cassandra fulfills the storage interface of
Apache::Session. Session data is stored in a Cassandra database.

=head1 SCHEMA

To use this module, you will need at least these columns in a table
called 'sessions':

  id text
  a_session text

To create this schema, you can execute this command using cqlsh:

  CREATE TABLE sessions (
     id text PRIMARY KEY,
     a_session text
  );

=head1 CONFIGURATION

The module must know what datasource, username, and password to use when
connecting to the database.  These values can be set using the options hash
(see Apache::Session documentation).  The options are DataSource, UserName,
and Password.

Example:

 tie %hash, 'Apache::Session::Cassandra', $id, {
     DataSource => 'dbi:Cassandra:host=localhost;keyspace=llng',
     UserName   => 'database_user',
     Password   => 'K00l'
 };

Instead, you may pass in an already-opened DBI handle to your database.

 tie %hash, 'Apache::Session::Cassandra', $id, {
     Handle => $dbh
 };

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::Store::DBI>

=head1 COPYRIGHT AND LICENSE

=encoding utf8

Copyright (C):

=over

=item 2009-2025 by Xavier Guimard

=item 2013-2025 by Clément Oudot

=item 2019-2025 by Maxime Besson

=item 2013-2025 by Worteks

=item 2023-2025 by Linagora

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
