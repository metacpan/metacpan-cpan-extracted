package Apache::Session::Browseable::Cassandra;

use strict;

use Apache::Session;
use Apache::Session::Lock::Null;
use Apache::Session::Browseable::Store::Cassandra;
use Apache::Session::Generate::SHA256;
use Apache::Session::Serialize::JSON;
use Apache::Session::Browseable::DBI;

our $VERSION = '1.3.13';
our @ISA     = qw(Apache::Session::Browseable::DBI Apache::Session);

sub populate {
    my $self = shift;

    $self->{object_store} =
      new Apache::Session::Browseable::Store::Cassandra $self;
    $self->{lock_manager} = new Apache::Session::Lock::Null $self;
    $self->{generate}     = \&Apache::Session::Generate::SHA256::generate;
    $self->{validate}     = \&Apache::Session::Generate::SHA256::validate;
    $self->{serialize}    = \&Apache::Session::Serialize::JSON::serialize;
    $self->{unserialize}  = \&Apache::Session::Serialize::JSON::unserialize;

    return $self;
}

1;

=pod

=head1 NAME

Apache::Session::Browseable::Cassandra - Apache::Session backend to store
sessions in a Cassadra database.

=head1 SYNOPSIS

  use Apache::Session::Browseable::Cassandra;
  
  my $args = {
       DataSource => 'dbi:Cassandra:host=localhost;keyspace=llng',
       UserName   => $db_user,
       Password   => $db_pass,
  
       # Choose your browseable fileds
       Index      => '_whatToTrace _session_kind _utime iAddr',
  };
  
  # Use it like Apache::Session
  my %session;
  tie %session, 'Apache::Session::Browseable::Cassandra', $id, $args;
  $session{uid} = 'me';
  $session{mail} = 'me@me.com';
  $session{unindexedField} = 'zz';
  untie %session;

=head1 DESCRIPTION

Apache::Session::Browseable::Cassandra is an implementation of Apache::Session
for Cassandra database.

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

=head1 AUTHOR

This module was written by Mike Langen <mike.langen@tamedia.ch>, based
on the original for Oracle.

=head1 SEE ALSO

L<Apache::Session>, L<Apache::Session::DBI>
1;

