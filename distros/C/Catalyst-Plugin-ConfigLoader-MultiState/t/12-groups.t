use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {
        local        => '12-local.conf',
        dir          => '12-conf',
    },
    config_group => ['.gr2', 'post'],
};
use Catalyst::Test 'TestApp';

my $cfg = TestApp->cfg;

is($cfg->{var9}, 9);

#gr1
is($cfg->{var1}, 11);
is($cfg->{rw1}, 11);
is($cfg->{rwt1}, 11);
is($cfg->{inner}{var1}, 11);
is($cfg->{inner}{rw1}, 11);
is($cfg->{inner}{rwt1}, 11);
is($cfg->{twice}{inner}{var1}, 11);
is($cfg->{twice}{inner}{rw1}, 11);
is($cfg->{twice}{inner}{rwt1}, 11);

is($cfg->{gr1_var}, 1200);

#gr2
is($cfg->{var2}, 22);
is($cfg->{rw2}, 22);
is($cfg->{rwt2}, 22);
is($cfg->{inner}{var2}, 22);
is($cfg->{inner}{rw2}, 22);
is($cfg->{inner}{rwt2}, 22);
is($cfg->{twice}{inner}{var2}, 22);
is($cfg->{twice}{inner}{rw2}, 22);
is($cfg->{twice}{inner}{rwt2}, 22);

#post.rw
is($cfg->{var3}, 33);
is($cfg->{rw3}, 33);
is($cfg->{rwt3}, 33);
is($cfg->{twice}{inner}{rw4}, 43);
is($cfg->{twice}{inner}{rwt4}, 43);
is($cfg->{post_rwt2}, 22);

