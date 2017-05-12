use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {local => '11-local.conf', dir => '11-conf'},
};
use Catalyst::Test 'TestApp';

my $cfg = TestApp->cfg;

is($cfg->{ok_not_rw}, undef);

is($cfg->{bs}, 'base string');
is($cfg->{str}, 'my string');
is($cfg->{concat}, 'my string concat');

is($cfg->{num}, 2);
is($cfg->{add}, 200);

is_deeply($cfg->{array}, [9,8,7,6,5]);
is($cfg->{arr_len}, "ARRLEN=5");

is_deeply($cfg->{hash}, {key => 'new value', key2 => 2});
is($cfg->{hash_val}, 'VALUE=new value');

is($cfg->{twr1}, 3);
is($cfg->{twr2}, 3);
is($cfg->{twr3}, 3);
is_deeply($cfg->{twr}, {key => 3});
