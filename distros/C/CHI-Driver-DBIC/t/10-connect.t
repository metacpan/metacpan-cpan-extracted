#!perl 
use 5.008;
use strict;
use warnings FATAL      => 'all';
use Test::More skip_all => "Needs hardcoded schema details.";
use MotorTRAK::MBFL2::TestUtils qw/get_schema get_mlogger /;

# CHI logging.
# use Log::Any::Adapter;
# Log::Any::Adapter->set('Log4perl');

my $logger = get_mlogger;

BEGIN {
  use_ok('CHI') || print "Bail out!\n";
}

my ( $chi, $schema );
ok( $schema = get_schema, "Got a schema" );

ok( $schema->resultset('Mbfl2Session')->search( {} )->count > 0, "Found some sessions" );

ok(
  $chi = CHI->new(
    driver             => 'DBIC',
    resultset          => $schema->resultset('Mbfl2Session'),
    expires_on_backend => 1,
    expires_in         => 30
  ),
  "Got a CHI object."
);

my $key = "testing_chi_dbic";
my $val = 1234;

ok( $chi->remove($key), "Remove key $key" );
ok( !$chi->get($key),   "Key $key not found." );
ok( $chi->set( $key, $val ), "Set $key to $val" );
sleep 2;
is( $chi->get($key), $val, "Retrieved key $key. It has value $val" );

sleep 30;
ok( !$chi->get($key), "$key has expired" );

ok( $chi->set( $key, $val ), "Set $key to $val" );
is( $chi->get($key), $val, "$key re-instated ready for persistence test" );

done_testing;

