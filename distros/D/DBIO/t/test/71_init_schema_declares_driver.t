# ABSTRACT: DBIO::Test->init_schema declares its driver -- the fake one offline, the caller's on a real DSN
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI ();
use DBIO::Test;
use DBIO::Storage::DBI;

# OFFLINE (karr k308, ADR 0067 point 4). The test storage is a driver: the mock
# path of init_schema declares DBIO::Test::Storage on the schema before it
# connects, like any other schema declares its driver. DBIO::Test::Schema is
# shared by the driver suites and keeps no driver in its class. A test against
# a real database names its driver (storage_type); without one init_schema
# refuses, with the hint to pass it.
#
# What this file claims:
#   1. the mock path returns a schema that declares the fake driver -- plain,
#      or the hybrid over a requested driver storage, which is a
#      DBIO::Test::Storage too -- and DBIO::Test::Schema itself declares none;
#   2. a dsn or connect_info without storage_type is refused before anything
#      connects, naming storage_type;
#   3. with storage_type the real path connects (lazily) through that driver,
#      and with replicated => 1 the master runs on it.
#
# THE SUBSTITUTIONS: a fake driver DBIO::K308Init, its storage defined here
# and registered for a DBD name no DBD carries; DBI->connect records that it
# was asked and returns nothing.

my @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { push @CONNECTS, $_[1]; return undef };
}

{
  package DBIO::K308Init::Storage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K308Init => __PACKAGE__);
  $INC{'DBIO/K308Init/Storage.pm'} = __FILE__;
}

my $DSN = 'dbi:K308Init:db=t';

# --- 1. the mock path declares the fake driver --------------------------------
is(DBIO::Test::Schema->storage_type, '::DBI',
  'DBIO::Test::Schema keeps no driver in its class');

{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  is $schema->storage_type, '+DBIO::Test::Storage',
    'the mock path declares DBIO::Test::Storage on the schema';
  isa_ok $schema->storage, 'DBIO::Test::Storage', '... and runs on it';
  is(DBIO::Test::Schema->storage_type, '::DBI', '... on its own clone, not on the shared class');
}

{
  my $schema = DBIO::Test->init_schema(no_deploy => 1, storage_type => 'DBIO::K308Init::Storage');
  my $declared = $schema->storage_type;
  $declared =~ s/^\+//;
  ok $declared->isa('DBIO::Test::Storage'),
    'with a driver storage the declared class is the hybrid, a DBIO::Test::Storage';
  ok $declared->isa('DBIO::K308Init::Storage'), '... over that driver';
  is ref($schema->storage), $declared, '... and the schema runs on it';
}

{
  my $schema = DBIO::Test->init_schema(no_deploy => 1, replicated => 1);
  isa_ok $schema->storage, 'DBIO::Replicated::Storage', 'the replicated mock path';
  is $schema->storage_type, '+DBIO::Test::Storage', '... declares the fake driver too';
  isa_ok $schema->storage->master->storage, 'DBIO::Test::Storage', '... and its master runs on it';
}

# --- 2. a real DSN needs the driver ------------------------------------------
for my $form (
  [ 'dsn'          => [ dsn => $DSN ] ],
  [ 'connect_info' => [ connect_info => [ $DSN, 'u', 'p' ] ] ],
  [ 'dsn, replicated' => [ dsn => $DSN, replicated => 1 ] ],
) {
  my ($what, $args) = @$form;
  @CONNECTS = ();
  throws_ok { DBIO::Test->init_schema(@$args, no_deploy => 1) }
    qr/needs the driver: pass storage_type/, "$what without storage_type: refused, naming storage_type";
  isa_ok $@, 'DBIO::Exception', "$what: what is thrown";
  like "$@", qr/ADR 0067/, "$what: ... naming the decision";
  is scalar(@CONNECTS), 0, "$what: ... and nothing connects";
}

# --- 3. ... and runs on the one it is given -----------------------------------
{
  @CONNECTS = ();
  my $schema = DBIO::Test->init_schema(
    dsn => $DSN, storage_type => 'DBIO::K308Init::Storage', no_deploy => 1,
  );
  isa_ok $schema->storage, 'DBIO::K308Init::Storage', 'a real DSN with storage_type: the storage';
  is scalar(@CONNECTS), 0, '... connected lazily';
}

{
  @CONNECTS = ();
  my $schema = DBIO::Test->init_schema(
    dsn => $DSN, storage_type => 'DBIO::K308Init::Storage', replicated => 1, no_deploy => 1,
  );
  isa_ok $schema->storage, 'DBIO::Replicated::Storage', 'a real DSN, replicated: the storage';
  is $schema->storage->backend_storage_class, 'DBIO::K308Init::Storage',
    '... whose backends are storages of the given driver';
  isa_ok $schema->storage->master->storage, 'DBIO::K308Init::Storage', '... the master among them';
}

done_testing;
