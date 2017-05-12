#!/usr/bin/perl -w

use strict;
use warnings 'all';
use lib qw( lib t/lib );
use Test::More 'no_plan';

use_ok('My::State');
use_ok('My::City');

# Check relationships:
can_ok( 'My::State',  'cities' );
can_ok( 'My::City',   'state' );

map { $_->delete } My::State->retrieve_all;
My::City->find_or_create(
  state_id  =>
    My::State->find_or_create(
      state_name => 'Colorado',
      state_abbr => 'CO'
    )->id,
  city_name => 'Denver',
);


# Object index on both the Class and an Object:
my @states = My::State->retrieve_all;
My::State->clear_object_index;
$states[0]->clear_object_index;


# Does the class have a column?:
ok(
  My::State->find_column('state_id'),
  'My::State has field state_id'
);
ok(
  ! My::State->find_column('lucky_charms'),
  'My::State does not have field lucky_charms'
);


# Fun with columns:
ok(
  scalar(My::State->columns),
  'Called columns on class'
);
ok(
  scalar($states[0]->columns),
  'Called columns on object'
);
ok(
  scalar(My::State->columns('All')),
  'Called columns(all) on class'
);
ok(
  scalar($states[0]->columns('All')),
  'Called columns(all) on object'
);
ok(
  scalar(My::State->columns('Primary')),
  'Called columns(primary) on class'
);
ok(
  scalar($states[0]->columns('Primary')),
  'Called columns(primary) on object'
);
ok(
  ! eval { My::State->columns('FooBar') },
  'Called columns(foobar) on class'
);
ok(
  ! eval { $states[0]->columns('FooBar') },
  'Called columns(foobar) on object'
);
ok(
  My::State->columns(All => My::State->columns),
  'Called columns(all => @cols) on class'
);
ok(
  $states[0]->columns(All => My::State->columns),
  'Called columns(all => @cols) on object'
);


# Call 'construct' as an object method:
ok(
  $states[0]->construct( $states[0] ),
  'Can call construct on an object'
);



# Call create on an object:
ok(
  My::State->create( %{$states[0]}, state_id => undef, ),
  'called create on a class'
);
ok(
  $states[0]->create( %{$states[0]}, state_id => undef, ),
  'called create on an object'
);


# Call update on the class - should fail:
eval { My::State->update };
ok(
  $@,
  'calling class->update dies'
);



# Call update when something hasn't been changed:
ok(
  $states[0]->update,
  'called update() on an unchanged object'
);
{
  # Mark it as changed, but nothing has changed:
  local $states[0]->{__Changed} = { };
  ok(
    $states[0]->update,
    'called update() on an unchanged object'
  );
}
{
  # Mark it as changed, but something strange is in the keys...
  local $states[0]->{__Changed} = 1;
  ok(
    $states[0]->update,
    'called update() on an unchanged object'
  );
}



# Call delete as a class method:
eval { My::State->delete };
ok(
  $@,
  'calling class->delete dies'
);


# discard changes:
{
  my $old_name = $states[0]->state_name;
  $states[0]->state_name( 'Foo' );
  ok(
    scalar(keys(%{ $states[0]->{__Changed} })),
    'the __Changed hashref is populated after making a field value change'
  );
  $states[0]->discard_changes;
  is(
    $states[0]->state_name => $old_name,
    'discard changes works'
  );
  ok(
    ! keys(%{ $states[0]->{__Changed} }),
    'the __Changed hashref is emptied after discard_changes'
  );
}


# fleshing out incomplete objects:
{
  My::State->clear_object_index;
  My::State->columns('Essential' => qw/
    state_id
  /);
  my $state = My::State->retrieve( 1 );
  ok(
    ! $state->{state_name},
    'state_name hash entry is blank'
  );
  ok(
    $state->state_name,
    'calling state_name fleshes out missing field data'
  );
  ok(
    $state->{state_name},
    'after method call, state_name hash entry is valid'
  );
  
  My::State->columns('Essential' => My::State->columns );
  is_deeply(
    [ My::State->columns('Essential') ],
    [ My::State->columns('All') ],
    'we have reset the Essential column group to include all fields'
  );
}


# Class: calling an invalid field or method:
{
  eval { My::State->foobar };
  like(
    $@,
    qr/Can't locate object method "foobar" via package "My::State"/i,
    'invalid class method call dies'
  );
}

# Object: calling an invalid field or method:
{
  eval { $states[0]->foobar };
  like(
    $@,
    qr/Can't locate object method "foobar" via package "My::State"/i,
    'invalid class method call dies'
  );
}



# DESTROY an object that has changes in it:
{
  my $warning;
  local $SIG{__WARN__} = sub {
    $warning = shift;
  };
  SCOPE: {
    my $state = My::State->retrieve( 1 );
    $state->state_name('Foo');
  };
  like $warning, qr/DESTROY'd without saving changes to state_name/,
    'Changing values without saving causes death';
}


# Deletion:
{
  my $test_state = My::State->create(
    state_name  => 'FooState',
    state_abbr  => 'FO',
  );
  ok( $test_state => 'Got FooState' );
  isa_ok( $test_state => 'My::State' );
  ok(  $test_state->id => 'id works' );
  ok( $test_state, 'bool overload before delete' );
  $test_state->delete;
  ok( ! $test_state, 'bool overload after delete' );
  isa_ok( $test_state, 'Class::DBI::Lite::Object::Has::Been::Deleted' );
}



# Misc properties - Class:
{
  is(
    My::State->schema,
    'DBI:SQLite:dbname=t/testdb'
  );
  is_deeply(
    My::State->dsn, 
    [
      'DBI:SQLite:dbname=t/testdb', '', ''
    ]
  );
  ok(
    ( ! My::State->triggers('before_create') ),
    'no triggers before_create'
  );
  is(
    scalar(My::State->triggers('after_delete')) => 0,
    'there is 1 after_delete trigger for My::State'
  );
}

# Misc properties - Object:
{
  is(
    $states[0]->schema,
    'DBI:SQLite:dbname=t/testdb'
  );
  is_deeply(
    $states[0]->dsn, 
    [
      'DBI:SQLite:dbname=t/testdb', '', ''
    ]
  );
  ok(
    ( ! $states[0]->triggers('before_create') ),
    'no triggers before_create'
  );
  is(
    scalar($states[0]->triggers('after_delete')) => 0,
    'there is 1 after_delete trigger for $states[0]'
  );
}



# Add the same trigger twice, make sure it is only called once:
{
  my $counter = 0;
  my $once = sub {
    $counter++;
  };
  My::State->add_trigger( before_update => $once );
  My::State->add_trigger( before_update => $once );
  my $old_name = $states[0]->state_name;
  $states[0]->state_name('FooState' . rand());
  $states[0]->update;
  is( $counter => 1, 'trigger was added twice but only called once' );
}




# Add a trigger that will cause any create actions to fail:
{
  my $failer = sub {
    die "TEST FAIL CREATE"
  };
  My::State->add_trigger( before_create => $failer );
  ok(
    ! eval { My::State->create( %{$states[0]}, state_id => undef ) },
    'cannot create because of failure'
  );
  like $@, qr/TEST FAIL CREATE/;
  $failer = sub { };
}



# Add a trigger that will cause any update actions to fail:
{
  my $failer = sub {
    die "TEST FAIL UPDATE"
  };
  My::State->add_trigger( before_update => $failer );
  $states[0]->state_name( 'Foo Updated' );
  ok(
    ! eval { $states[0]->update },
    'cannot update because of failure'
  );
  like $@, qr/TEST FAIL UPDATE/;
  $failer = sub { };
  $states[0]->discard_changes;
}



# Add a trigger that will cause any delete actions to fail:
{
  my $failer = sub {
    die "TEST FAIL DELETE"
  };
  My::State->add_trigger( before_delete => $failer );
  ok(
    ! eval { $states[0]->delete },
    'cannot delete because of failure'
  );
  like $@, qr/TEST FAIL DELETE/;
  $failer = sub { };
}




# search_where on an object:
{
  $states[0]->search_where( state_name => 'foo' );
  $states[0]->search_where({ state_name => 'foo' });
  $states[0]->search_where(
    { state_name => 'foo' },
    { order_by => 'state_name' }
  );
  $states[0]->search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1 },
  );
  $states[0]->search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1, offset => 0 },
  );
}


# count_search_where on an object:
{
  $states[0]->count_search_where( state_name => 'foo' );
  $states[0]->count_search_where({ state_name => 'foo' });
  $states[0]->count_search_where(
    { state_name => 'foo' },
    { order_by => 'state_name' }
  );
  $states[0]->count_search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1 },
  );
  $states[0]->count_search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1, offset => 0 },
  );
}



# search_where on a class:
{
  My::State->search_where( state_name => 'foo' );
  My::State->search_where({ state_name => 'foo' });
  My::State->search_where(
    { state_name => 'foo' },
    { order_by => 'state_name' }
  );
  My::State->search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1 },
  );
  My::State->search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1, offset => 0 },
  );
}


# count_search_where on a class:
{
  My::State->count_search_where( state_name => 'foo' );
  My::State->count_search_where({ state_name => 'foo' });
  My::State->count_search_where(
    { state_name => 'foo' },
    { order_by => 'state_name' }
  );
  My::State->count_search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1 },
  );
  My::State->count_search_where(
    { state_name => 'foo' },
    { order_by => 'state_name', limit => 1, offset => 0 },
  );
}



# dbi_commit when we're not in a transaction:
{
 eval { $states[0]->dbi_commit };
}


# has_many on an object:
{
  eval {
    $states[0]->has_many(
      cities  =>
        'My::City'  =>
          'state_id'
    );
  };
}


# has_a on an object:
{
  my ($city) = $states[0]->cities;
  eval {
    $city->has_a(
      state  =>
        'My::State'  =>
          'state_id'
    );
  };
}



# Call add_to_cities with a hashref:
{
  my ($city) = $states[0]->cities;
  my $new_city = $states[0]->add_to_cities(
    { %$city, city_id => undef }
  );
  ok( $new_city, 'got a new object' );
  isa_ok( $new_city => 'My::City' );
  is_deeply( $new_city->state, $states[0] );
  $new_city->delete;
}

# Call add_to_cities with a hash:
{
  my ($city) = $states[0]->cities;
  my $new_city = $states[0]->add_to_cities(
    %$city, city_id => undef
  );
  ok( $new_city, 'got a new object' );
  isa_ok( $new_city => 'My::City' );
  is_deeply( $new_city->state, $states[0] );
  $new_city->delete;
}

# Call add_to_cities with extra fields:
{
  my ($city) = $states[0]->cities;
  my $new_city = $states[0]->add_to_cities(
    %$city,
    foo => 'bar',
    baz => 'bux',
    city_id => $city->id,
    nonexist => undef,
  );
  ok( $new_city, 'got a new object' );
  isa_ok( $new_city => 'My::City' );
  is_deeply( $new_city->state, $states[0] );
  $new_city->delete;
}


# Try to set up a table that does not exist:
{
  eval {
    My::City->set_up_table('provinces')
  };
  like $@, qr/Table provinces doesn't exist or has no columns/i,
    'attempt to set up invalid table fails';
}


# Call reset on an iterator:
{
  my $iter = My::State->retrieve_all;
  $iter->reset;
  is( $iter->{idx} => 0, 'reset on an iterator sets its internal index to zero' );
}


# Simple accessor/mutators for the entity meta:
{
  is( My::State->_meta->table => 'states' );
  ok( scalar(My::State->_meta->triggers) );
  ok( My::State->_meta->has_a_rels );
  ok( My::State->_meta->has_many_rels );
}








