use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {local => '09_10-local.conf', dir => '09_10-conf'},
};
use Catalyst::Test 'TestApp';

my $cfg = TestApp->cfg;

is($cfg->{test}, 1);
is($cfg->{second_test}, 2);
is($cfg->{third_test}, 3);

isa_ok($cfg->{level1}, 'HASH');
is($cfg->{level1}{test}, 4);
isa_ok($cfg->{second_level1}, 'HASH');
is($cfg->{second_level1}{test}, 5);
is($cfg->{second_level1}{test2}, 6);

isa_ok($cfg->{level2}, 'HASH');
isa_ok($cfg->{level2}{here}, 'HASH');
is($cfg->{level2}{here}{test}, 7);

is($cfg->{test_deep_to_root}, 10);

isa_ok($cfg->{'Plugin::Pizda'}, 'HASH');
is_deeply($cfg->{'Plugin::Pizda'}{pizdec_nahuy}, [9,8,7]);

is($cfg->{'Embed::Module'}{test}, 100);
