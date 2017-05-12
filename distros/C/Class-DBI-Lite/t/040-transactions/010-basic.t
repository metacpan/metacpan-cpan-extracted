#!/usr/bin/perl -w

use strict;
use warnings 'all';
use lib qw( lib t/lib );
use Test::More 'no_plan';
use Data::Dumper;
use Carp 'confess';

use_ok('My::State');
use_ok('My::City');

ok( my $state = My::State->retrieve( 1 ) );


# Clear out any test data:
map { $_->delete } $state->cities;
ok( ! $state->cities->count, 'state has no cities' );


# New transaction:
{
  local My::City->db_Main->{AutoCommit};
  my $city = My::City->create(
    state_id  => $state->id,
    city_name => 'test-city'
  );
  My::City->dbi_rollback;
}
ok( ! $state->cities->count, 'Rollback 1 succeeded' );

# Clear out any test data:
map { $_->delete } $state->cities;
ok( ! $state->cities->count, 'state has no cities' );


eval {
  $state->do_transaction(sub {
    my $city = My::City->create(
      state_id  => $state->id,
      city_name => 'test-city111'
    );
    local $^W;
    $SIG{__WARN__} = sub {};
    die "This should fail";
  });
};
ok( ! $state->cities->count, 'Rollback 2 succeeded' );


# Clear out any test data:
map { $_->delete } $state->cities;
ok( ! $state->cities->count, 'state has no cities' );



# Now actually do the transaction:
$state->do_transaction(sub {
  My::City->create(
    state_id  => $state->id,
    city_name => 'test',
  );
});

is( $state->cities->count => 1, 'Transaction succeeded' );



# Clear out any test data:
map { $_->delete } $state->cities;
ok( ! $state->cities->count, 'state has no cities' );







