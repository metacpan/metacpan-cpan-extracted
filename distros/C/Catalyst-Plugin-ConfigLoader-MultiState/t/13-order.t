use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {local => '13-local.conf', dir => '13-conf'},
};
use Catalyst::Test 'TestApp';

my $cfg = TestApp->cfg;

is($cfg->{num}, 'rcba');
is($cfg->{inner}{num}, '010203');
is($cfg->{jopa}{num}, 'ns1 jopa');
is($cfg->{aaahhh}{num}, 'ns1 jopa aaahhh');
is($cfg->{subtest}{num}, 4);
is($cfg->{subtest}{result}, "RESULT=4");
