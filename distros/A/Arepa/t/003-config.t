use strict;
use warnings;

use Test::More tests => 9;
use Test::Deep;
use Arepa::Config;

use constant TEST_CONFIG_FILE => 't/config-test.yml';

my $c = Arepa::Config->new(TEST_CONFIG_FILE);
is($c->get_key('package_db'),
   "t/test-package.db",
   "Simple configuration keys should work");
is($c->get_key('upload_queue:path'),
   '/home/zoso/src/apt-web/incoming',
   "Nested configuration key should work");
unlink $c->get_key('package_db');

cmp_deeply([ $c->get_builders ],
           bag(qw(lenny64 lenny32 etch64 etch32)),
           "Builder information should be correct");

my $expected_builder_info = {
    name                 => 'lenny64',
    type                 => 'sbuild',
    architecture         => 'amd64',
    architecture_all     => 'yes',
    distribution         => 'lenny-opera',
    distribution_aliases => [qw(lenny)],
    bin_nmu_for          => [qw(unstable)],
};
cmp_deeply({ $c->get_builder_config('lenny64') },
           $expected_builder_info,
           "Builder information for 'lenny64' should be correct");
is($c->get_builder_config_key('lenny64', 'architecture'),
   'amd64',
   "Should find the same values when asking for single configuration keys");
eval {
    $c->get_builder_config_key('lenny64', 'architecture2');
};
ok($@, "Non-existent config key retrieval should throw an exception");


# Non-existent keys
ok($c->key_exists('repository:path'),
   "key_exists should find existent keys");
ok(!$c->key_exists('repository:non_path'),
   "key_exists should NOT find non-existent keys");
my $pass = 1;
eval {
    $c->get_key('repository:non_path');
    $pass = 0;
};
ok($pass, "get_key should die when given a non-existent key");
