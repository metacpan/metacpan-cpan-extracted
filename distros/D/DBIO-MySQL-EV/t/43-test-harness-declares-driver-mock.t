use strict;
use warnings;
use Test::More;

# karr k93, core ADR 0067 section 4: a driver's test helper declares its own
# driver by default. DBIO::MySQL::EV::TestHarness hands core's
# DBIO::Test::AsyncHarness::new the storage_type DBIO::MySQL::Storage when the
# schema class declares no driver, so the shared DBIO::Test::Schema connects
# instead of being refused; a storage_type the caller passes wins, and a schema
# class that declares its own storage is left alone. Offline: the harness's
# connect is lazy, nothing is opened.

use DBIO::MySQL::EV::TestHarness;
use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;
use DBIO::Test::Schema;

{
  package T43::Storage;
  use base 'DBIO::MySQL::Storage';
}
{
  # declares its driver by a storage subclass, no component
  package T43::OwnStorageSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T43::Storage');
}
{
  # declares nothing, in the reference form of storage_type
  package T43::RefGenericSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type([ '::DBI', {} ]);
}

my $DRIVER = 'DBIO::MySQL::Storage';

subtest 'what the harness hands to core' => sub {
  # Core's new is replaced for this part, so the claim is about the defaulting
  # alone and holds on every core, also one that ignores storage_type.
  my @handed;
  no warnings 'redefine';
  local *DBIO::Test::AsyncHarness::new = sub {
    my ($class, %opts) = @_;
    push @handed, \%opts;
    return bless {}, $class;
  };

  my $handed = sub {
    @handed = ();
    DBIO::MySQL::EV::TestHarness->new(@_);
    is scalar @handed, 1, 'core new called once';
    return $handed[0];
  };

  my $o = $handed->(schema_class => 'DBIO::Test::Schema');
  is $o->{storage_type}, $DRIVER,
    'a schema class without a driver gets the MySQL driver';
  is $o->{schema_class}, 'DBIO::Test::Schema', 'schema_class handed on';

  $o = $handed->(
    schema_class => 'DBIO::Test::Schema',
    storage_type => 'DBIO::MySQL::Storage::MariaDB',
  );
  is $o->{storage_type}, 'DBIO::MySQL::Storage::MariaDB',
    'a passed storage_type wins over the default';

  $o = $handed->(schema_class => 'T43::RefGenericSchema');
  is $o->{storage_type}, $DRIVER,
    'the generic storage in reference form declares no driver either';

  $o = $handed->(schema_class => 'T43::OwnStorageSchema');
  ok !defined $o->{storage_type},
    'a schema class declaring its own storage gets no storage_type: its declaration stands';

  $o = $handed->(
    schema_class => 'T43::OwnStorageSchema',
    storage_type => 'DBIO::MySQL::Storage::MariaDB',
  );
  is $o->{storage_type}, 'DBIO::MySQL::Storage::MariaDB',
    'a passed storage_type is handed on for a declaring class too';

  $o = $handed->();
  is $o->{storage_type}, $DRIVER,
    'the default schema class (driver component, generic class storage_type) gets it as well';
  ok !exists $o->{schema_class}, 'no schema_class is invented for core';
};

subtest 'against core: the refusal is avoided' => sub {
  plan skip_all => 'core before ADR 0067: no schema is refused for want of a '
                 . 'driver and AsyncHarness ignores storage_type'
    unless DBIO::Schema->can('_refuse_undeclared_driver');
  plan skip_all => 'EV and EV::MariaDB needed for the harness to construct'
    unless eval { require EV; require EV::MariaDB; 1 };

  # A DSN that is never connected to: the harness only needs one to construct.
  local $ENV{DBIO_TEST_MYSQL_DSN} = 'dbi:MariaDB:database=dbio_k93;host=127.0.0.1;port=9';
  local $ENV{DBIO_TEST_MYSQL_USER} = 'nobody';
  local $ENV{DBIO_TEST_MYSQL_PASS} = 'none';

  # The rule the default answers: the shared schema, connected as it is.
  my $err = do {
    local $@;
    eval {
      DBIO::Test::Schema->connect(
        $ENV{DBIO_TEST_MYSQL_DSN}, 'nobody', 'none', { async => 'ev' },
      );
    };
    $@;
  };
  like $err, qr/declares no driver/,
    'core refuses DBIO::Test::Schema connected without a driver';

  my $h = eval { DBIO::MySQL::EV::TestHarness->new(schema_class => 'DBIO::Test::Schema') };
  is $@, '', 'the harness connects DBIO::Test::Schema';
  isa_ok $h->schema->storage, $DRIVER, 'its storage';
  is $h->{storage_type}, $DRIVER, 'core keeps the driver for further connections';
  is(DBIO::Test::Schema->storage_type, '::DBI',
    'the shared schema class itself stays undeclared');
  ok !$h->schema->storage->_dbh, 'nothing was connected';

  $h = DBIO::MySQL::EV::TestHarness->new(
    schema_class => 'DBIO::Test::Schema',
    storage_type => 'DBIO::MySQL::Storage::MariaDB',
  );
  isa_ok $h->schema->storage, 'DBIO::MySQL::Storage::MariaDB',
    'with a passed storage_type, its storage';

  $h = DBIO::MySQL::EV::TestHarness->new(schema_class => 'T43::OwnStorageSchema');
  isa_ok $h->schema->storage, 'T43::Storage',
    "a declaring class's own storage";

  $h = DBIO::MySQL::EV::TestHarness->new;
  isa_ok $h->schema->storage, $DRIVER, 'the default schema, its storage';
};

done_testing;
