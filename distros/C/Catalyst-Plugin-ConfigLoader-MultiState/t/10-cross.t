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

#root
isa_ok($cfg->{cat_home}, 'Path::Class::Dir');
isa_ok($cfg->{cat_root}, 'Path::Class::Dir');
is($cfg->{pre_var}, 'predefined');
is($cfg->{has_pre}, 'predefined');
is($cfg->{num}, 5);
is($cfg->{num_plus_10}, 15);

#local
is($cfg->{acc_local}, 'predefined');
is($cfg->{second_level1}{i_see_test}, 5);

#upper
is($cfg->{acc_upper_fake}, 'predefined');
is($cfg->{second_level1}{i_see_upper}, 'predefined');
is($cfg->{level2}{here}{i_see_var}, 'var');

#path
is($cfg->{p1}, 5);
is($cfg->{p2}, 5);
is($cfg->{p3}, 4);
is($cfg->{p4}, 'var');
