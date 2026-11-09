# ABSTRACT: a replicated schema runs its master and replicants on the driver it declares
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI ();
use DBIO;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Replicated::Storage;
use DBIO::Test::Storage;

# OFFLINE (karr k308, ADR 0067 point 3). DBIO::Replicated is a storage over a
# driver, not a driver: the master and every replicant are storages of the
# driver the schema declares.
#
# What this file claims:
#   1. backend_storage_class defaults to the declared driver's storage class,
#      read before DBIO::Replicated::connection sets the replicated one -- for
#      a driver declared by shortcut and by a driver component loaded before
#      Replicated; the master is a storage of that driver;
#   2. a repeated connect keeps it: on the class, and on a connected object;
#   3. a backend_storage_class in the connect info wins, and is itself a
#      declaration;
#   4. a replicated schema that declares no driver, and gives no
#      backend_storage_class, is refused before any storage is built.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K308Rep, its storage defined here and
# registered for a DBD name no DBD carries; DBI->connect records that it was
# asked and returns nothing. Determining the driver of a declared storage
# connects nothing.

my @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { push @CONNECTS, $_[1]; return undef };
}

{
  package DBIO::K308Rep::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K308Rep => __PACKAGE__);
  $INC{'DBIO/K308Rep/Storage.pm'} = __FILE__;
}
{
  package DBIO::K308Rep;
  use base 'DBIO::Base';
  $INC{'DBIO/K308Rep.pm'} = __FILE__;
  sub connection {
    my $self = shift;
    $self->storage_type('+DBIO::K308Rep::Storage');
    return $self->next::method(@_);
  }
}
BEGIN {
  package DBIO::Shortcut::k308rep;
  sub apply { DBIO->apply_driver($_[1], 'K308Rep') }
  $INC{'DBIO/Shortcut/k308rep.pm'} = __FILE__;
}

{
  package T::K308Rep::Shortcut;
  use DBIO 'Schema', -k308rep;
  __PACKAGE__->load_components('Replicated');
}
{
  package T::K308Rep::Component;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components(qw( +DBIO::K308Rep Replicated ));
}
{
  package T::K308Rep::NoDriver;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Replicated');
}
{
  package T::K308Rep::ClassLevel;
  use DBIO 'Schema', -k308rep;
  __PACKAGE__->load_components('Replicated');
}

my $DSN = 'dbi:K308Rep:db=t';
my @KEEP;

sub backend_of {
  my ($schema) = @_;
  my $storage = $schema->storage;
  return ( $storage->backend_storage_class, ref $storage->master->storage );
}

# --- 1. the declared driver is the backend -----------------------------------
for my $class (qw( T::K308Rep::Shortcut T::K308Rep::Component )) {
  @CONNECTS = ();
  my $schema = $class->connect($DSN, 'u', 'p');
  push @KEEP, $schema;
  isa_ok $schema->storage, 'DBIO::Replicated::Storage', "$class: the storage";
  is_deeply [ backend_of($schema) ], [ 'DBIO::K308Rep::Storage', 'DBIO::K308Rep::Storage' ],
    "$class: backend_storage_class is the declared driver's, and so is the master";
  is scalar(@CONNECTS), 0, "$class: ... and nothing connected";

  # --- 2. ... and stays so on a repeated connect on the connected object
  $schema->connection($DSN, 'u', 'p');
  is_deeply [ backend_of($schema) ], [ 'DBIO::K308Rep::Storage', 'DBIO::K308Rep::Storage' ],
    "$class: a repeated connection on the object keeps the backend";
}

# --- 2. a repeated connect on the class ---------------------------------------
{
  T::K308Rep::ClassLevel->connection($DSN, 'u', 'p');
  T::K308Rep::ClassLevel->connection($DSN, 'u', 'p');
  is_deeply [ backend_of('T::K308Rep::ClassLevel') ],
    [ 'DBIO::K308Rep::Storage', 'DBIO::K308Rep::Storage' ],
    'a repeated connection on the class keeps the backend';
}

# --- 3. the connect info wins, and declares ----------------------------------
{
  my $schema = T::K308Rep::Shortcut->connect(
    $DSN, 'u', 'p', { backend_storage_class => 'DBIO::Test::Storage' },
  );
  push @KEEP, $schema;
  is_deeply [ backend_of($schema) ], [ 'DBIO::Test::Storage', 'DBIO::Test::Storage' ],
    'a backend_storage_class in the connect info wins over the declared driver';

  my $declared = T::K308Rep::NoDriver->connect(
    $DSN, 'u', 'p', { backend_storage_class => 'DBIO::Test::Storage' },
  );
  push @KEEP, $declared;
  is_deeply [ backend_of($declared) ], [ 'DBIO::Test::Storage', 'DBIO::Test::Storage' ],
    '... and is a declaration of its own on a schema that declares none';
}

# --- 4. no driver: refused ---------------------------------------------------
{
  @CONNECTS = ();
  my $built = 0;
  no warnings 'redefine';
  local *DBIO::Replicated::Storage::new = do {
    my $orig = \&DBIO::Replicated::Storage::new;
    sub { $built++; goto &$orig };
  };
  use warnings 'redefine';

  throws_ok { T::K308Rep::NoDriver->connect($DSN, 'u', 'p') }
    qr/Schema class T::K308Rep::NoDriver declares no driver/,
    'a replicated schema without a driver is refused';
  isa_ok $@, 'DBIO::Exception', '... what is thrown';
  like "$@", qr/DBIO::Replicated runs the master and every replicant on the driver/,
    '... saying that replication runs on the declared driver';
  is $built, 0, '... before any storage is built';
  is scalar(@CONNECTS), 0, '... and nothing connects';
}

done_testing;
