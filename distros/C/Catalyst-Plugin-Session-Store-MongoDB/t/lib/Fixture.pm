package Fixture;
use Moose;
use namespace::autoclean;

use String::Random;

has 'collection' => (
  isa => 'MongoDB::Collection',
  is => 'ro',
  lazy_build => 1,
);

has 'store' => (
  isa => 'Catalyst::Plugin::Session::Store::MongoDB',
  is => 'ro',
  lazy_build => 1,
);

has '_cleanup' => (
  isa => 'ArrayRef',
  is => 'rw',
);

has '_random' => (
  isa => 'String::Random',
  is => 'ro',
  lazy_build => 1,
);

sub _build_collection {
  my ($self) = @_;

  return $self->store->_collection;
}

sub _build_store {
  return Catalyst::Plugin::Session::Store::MongoDB->new(
    client_options => {
      host => $ENV{MONGODB_HOST},
      port => $ENV{MONGODB_PORT},
    },
    dbname => $ENV{TEST_DB},
    collectionname => $ENV{TEST_COLLECTION},
  );
}

sub _build__random {
  return String::Random->new();
}

sub setup {
  my ($self) = @_;

  my @needs = qw/MONGODB_HOST MONGODB_PORT TEST_DB TEST_COLLECTION/;
  map {
    return 'Must set '.join(",", @needs).' environment variables'
      unless(defined($ENV{$_}));
  } @needs;

  return undef;
}

sub teardown {
  my ($self) = @_;

  $self->store->delete_session_data($_) foreach (@{$self->{_cleanup}});
}

sub new_id {
  my ($self) = @_;

  my ($id, $found);
  do {
    $id = sprintf("%i", int(rand(1000000)));
    $found = $self->collection->find_one({ _id => $id });
  } while ($found);

  push(@{$self->{_cleanup}}, $id);
  
  return $id;
}

sub new_data {
  my ($self) = @_;

  return $self->_random->randpattern("..............................");
}

1;
