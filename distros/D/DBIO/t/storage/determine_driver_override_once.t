use strict;
use warnings;

use Test::More;

use DBIO::Test;

# The methods at the top of DBIO::Storage::DBI fire the driver determination
# on first use, then re-dispatch so the class the determination settled on
# answers (karr k345). A driver storage is declared from the start (ADR 0059,
# ADR 0067), so its own override of such a method sits ABOVE the wrapper and
# is what the caller reaches first; it reaches the wrapper through
# next::method. Re-dispatching from there ran the override a second time, the
# inner run's result came back to the outer one, and a hook that appends to
# what next::method returns appended twice -- Oracle's "FROM DUAL FROM DUAL",
# DB2's and Firebird's dummy tables likewise, on the first call of a fresh
# storage. An override runs exactly once per call, determined or not.

my $schema = DBIO::Test->init_schema(no_deploy => 1);

our %RAN;

{
  # A declared driver whose hooks extend what the base answers, the shape of
  # the Oracle, DB2 and Firebird storages.
  package T::Once::DriverStorage;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';

  sub _exists_value_sql {
    my $self = shift;
    $main::RAN{exists}++;
    return $self->next::method(@_) . ' FROM MARKER';
  }

  sub _set_operation_keyword {
    my ($self, $op) = @_;
    $main::RAN{keyword}++;
    return $self->next::method($op);
  }

  sub _random_function {
    my $self = shift;
    $main::RAN{random}++;
    return 'MARKED_' . $self->next::method(@_);
  }
}

DBIO::Storage::DBI->register_driver('FakeOnceDrv' => 'T::Once::DriverStorage');

sub fresh_storage {
  my $storage = T::Once::DriverStorage->new($schema);
  $storage->connect_info([ 'dbi:FakeOnceDrv:', '', '' ]);
  ok !$storage->_driver_determined, 'a fresh declared storage is not determined yet';
  return $storage;
}

{
  local %RAN;
  my $storage = fresh_storage();

  is $storage->_exists_value_sql('(SELECT 42)'),
    'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM MARKER',
    'the first call on a fresh storage appends the dummy table once';
  is $RAN{exists}, 1, 'and runs the driver override once';
  ok $storage->_driver_determined, 'the call determined the driver';

  is $storage->_exists_value_sql('(SELECT 42)'),
    'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM MARKER',
    'the second call, determined, renders the same';
  is $RAN{exists}, 2, 'and runs the override once more';
}

{
  local %RAN;
  my $storage = fresh_storage();

  is $storage->_set_operation_keyword('union'), 'UNION',
    'a delegating override answers the base keyword';
  is $RAN{keyword}, 1, 'and runs once on the first call of a fresh storage';
}

{
  local %RAN;
  my $storage = fresh_storage();

  is $storage->_random_function, 'MARKED_RANDOM()',
    'the same holds for every method on the determination list';
  is $RAN{random}, 1, 'the override of _random_function runs once';
}

# The re-dispatch itself stays: entered on a class without an override, the
# determination may move the storage to its access-path class, and that
# class's override answers the very first call.

{
  package T::Once::PathDriver;
  use base 'DBIO::Storage::DBI';
  use mro 'c3';
  sub _adapt_to_access_path {
    my ($self, $dbd) = @_;
    bless $self, 'T::Once::PathDriver::Path'
      if defined $dbd and $dbd eq 'FakeOncePathDrv';
  }
}
{
  package T::Once::PathDriver::Path;
  use base 'T::Once::PathDriver';
  use mro 'c3';
  sub _exists_value_sql {
    my $self = shift;
    $main::RAN{path}++;
    return $self->next::method(@_) . ' FROM PATH';
  }
}

DBIO::Storage::DBI->register_driver('FakeOncePathDrv' => 'T::Once::PathDriver');

{
  local %RAN;
  my $storage = T::Once::PathDriver->new($schema);
  $storage->connect_info([ 'dbi:FakeOncePathDrv:', '', '' ]);

  is $storage->_exists_value_sql('(SELECT 42)'),
    'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END FROM PATH',
    'the access-path class the determination settled on answers the first call';
  isa_ok $storage, 'T::Once::PathDriver::Path';
  is $RAN{path}, 1, 'its override runs once';
}

done_testing;
