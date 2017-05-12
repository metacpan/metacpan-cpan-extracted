package Catalyst::Model::MongoDB;
our $AUTHORITY = 'cpan:GETTY';
$Catalyst::Model::MongoDB::VERSION = '0.13';
# ABSTRACT: MongoDB model class for Catalyst
use MongoDB;
use MongoDB::OID;
use Moose;
use version;

BEGIN { extends 'Catalyst::Model' }

has host           => ( isa => 'Str', is => 'ro', required => 1, default => sub { 'localhost' } );
has port           => ( isa => 'Int', is => 'ro', required => 1, default => sub { 27017 } );
has dbname         => ( isa => 'Str', is => 'ro' );
has collectionname => ( isa => 'Str', is => 'ro' );
has gridfsname     => ( isa => 'Str', is => 'ro' );
has username       => ( isa => 'Str', is => 'ro', predicate => 'has_username' );
has password       => ( isa => 'Str', is => 'ro', predicate => 'has_password' );
has find_master    => ( isa => 'Int', is => 'ro', default => sub { 0 } );

has 'connection' => (
  isa => 'MongoDB::MongoClient',
  is => 'rw',
  lazy_build => 1,
);

sub _build_connection {
  my ($self) = @_;

  my $conn = MongoDB::MongoClient->new(
      host => $self->host,
      port => $self->port,
      find_master => $self->find_master,
      ( $self->dbname ? ( dbname => $self->dbname ) : () ),
  );

  # attempt authentication only if we have all three parameters for
  # MongoDB::Connection->authenticate()
  if ($self->dbname && $self->has_username && $self->has_password) {
      $conn->authenticate($self->dbname, $self->username, $self->password)
          if version->parse($MongoDB::VERSION) < 1.0;
  }

  return $conn;
}

has 'dbs' => (
  isa => 'HashRef[MongoDB::Database]',
  is => 'rw',
  default => sub {{}},
);

sub db {
  my ( $self, $dbname ) = @_;
  $dbname = $self->dbname if !$dbname;
  confess "no dbname given via parameter or config" if !$dbname;
  if (!$self->dbs->{$dbname}) {
    $self->dbs->{$dbname} = $self->connection->get_database($dbname);
  }
  return $self->dbs->{$dbname};
}

*c = \&collection;
*coll = \&collection;
sub collection {
  my ( $self, $param ) = @_;
  my $dbname;
  my $collname;
  my @params;
  if ($param) {
	@params = split(/\./,$param)
  }
  if (@params > 1) {
	$dbname = $params[0];
	$collname = $params[1];
  } else {
    $dbname = $self->dbname;
	if (@params == 1) {
      $collname = $params[0];
	} else {
      $collname = $self->collectionname;
	}
  }
  confess "no dbname given via parameter or config" if !$dbname;
  confess "no collectionname given via parameter or config" if !$collname;
  $self->db($dbname)->get_collection($collname);
}

sub run {
  my ( $self, @params ) = @_;
  confess "no dbname given via config" if !$self->dbname;
  $self->db->run_command(@params);
}

sub eval {
  my ( $self, @params ) = @_;
  confess "no dbname given via config" if !$self->dbname;
  $self->db->eval(@params);
}

*collnames = \&collection_names;
sub collection_names {
  my ( $self, @params ) = @_;
  confess "no dbname given via config" if !$self->dbname;
  $self->db->collection_names(@params);
}

*g = \&gridfs;
sub gridfs {
  my ( $self, $param ) = @_;
  my $dbname;
  my $gridfsname;
  my @params = split(/\./,$param);
  if (@params > 1) {
	$dbname = $params[0];
	$gridfsname = $params[1];
  } else {
    $dbname = $self->dbname;
	if (@params == 1) {
      $gridfsname = $params[0];
	} else {
      $gridfsname = $self->gridfsname;
	}
  }
  confess "no dbname given via parameter or config" if !$dbname;
  confess "no gridfsname given via parameter or config" if !$gridfsname;
  $self->db($dbname)->get_gridfs($gridfsname);
}

*dbnames = \&database_names;
sub database_names {
  my ( $self ) = @_;
  $self->connection->database_names;
}

sub oid {
  my( $self, $_id ) = @_;
  return MongoDB::OID->new( value => $_id );
}

sub authenticate {
  my( $self, @params ) = @_;
  return $self->connection->authenticate(@params);
}

1;

__END__

=pod

=head1 NAME

Catalyst::Model::MongoDB - MongoDB model class for Catalyst

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    #
    # Config
    #
    <Model::MyModel>
        host localhost
        port 27017
        dbname mydatabase
        username myuser
        password mypass
        collectionname preferedcollection
        gridfs preferedgridfs
    </Model::MyModel>

    #
    # Usage
    #
    $c->model('MyModel')->db                           # returns MongoDB::MongoClient->get_database
    $c->model('MyModel')->db('otherdb')                # returns ->otherdb
    $c->model('MyModel')->collection                   # returns ->mydatabase->preferedcollection
    $c->model('MyModel')->coll                         # the same...
    $c->model('MyModel')->c                            # the same...
    $c->model('MyModel')->c('otherdb.othercollection') # returns ->otherdb->othercollection
    $c->model('MyModel')->c('somecollection')          # returns ->mydatabase->somecollection
    $c->model('MyModel')->gridfs                       # returns ->mydatabase->get_gridfs('preferedgridfs')
    $c->model('MyModel')->g                            # the same...
    $c->model('MyModel')->g('somegridfs')              # returns ->mydatabase->get_gridfs('somegridfs')
    $c->model('MyModel')->g('otherdb.othergridfs')     # returns ->otherdb->get_gridfs('othergridfs')

    $c->model('MyModel')->run(...)                     # returns ->mydatabase->run_command(...)
    $c->model('MyModel')->eval(...)                    # returns ->mydatabase->eval(...)

    $c->model('MyModel')->database_names               # returns ->database_names
    $c->model('MyModel')->dbnames                      # the same...

=head1 DESCRIPTION

This model class exposes L<MongoDB::MongoClient> as a Catalyst model.

=head1 CONFIGURATION

You can pass the same configuration fields as when you make a new L<MongoDB::MongoClient>.

In addition you can also give a database name via dbname, a collection name via collectioname or 
a gridfs name via gridfsname.

=head2 AUTHENTICATION

If all three of C<username>, C<password>, and C<dbname> are present, this class
will authenticate via MongoDB::MongoClient->authenticate().  (See
L<MongoDB::MongoClient|MongoDB::MongoClient> for details).

=head1 METHODS

=head2 dbnames

=head2 database_names

List of databases.

=head2 collnames

=head2 collection_names

List of collection names of the default database. You cant give other database names here, if you need this please do:

  $c->model('MyModel')->db('otherdatabase')->collection_names

=head2 collection

=head2 coll

=head2 c

Gives back a MongoDB::Collection, you can also directly access other dbs collections, with "otherdb.othercollection".
If no collectionname is given he uses the default collectionname given on config.

=head2 gridfs

=head2 g

Gives back a MongoDB::GridFS. If no gridfsname is given, he uses the default gridfsname given on config.

=head2 run

Run a command via MongoDB::Database->run_command on the default database. You cant give other database names here,
if you need this please do:

  $c->model('MyModel')->db('otherdatabase')->run_command(...)

=head2 eval

Eval code via MongoDB::Database->eval on the default database. You cant give other database names here,
if you need this please do:

  $c->model('MyModel')->db('otherdatabase')->eval(...)

=head2 oid

Creates MongoDB::OID object

=head2 authenticate

[re]authenticate after the initial connection, or
authenticate to multiple databases within the same model.

=head1 SUPPORT

IRC

  Join #catalyst on irc.perl.org and ask for Getty.

Repository

  http://github.com/singingfish/p5-catalyst-model-mongodb
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/singingfish/p5-catalyst-model-mongodb/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Raudssus Social Software.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
