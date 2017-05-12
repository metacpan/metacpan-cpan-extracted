use strict;
use warnings;
use Test::More qw/no_plan/;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestApp {
    'Plugin::ConfigLoader::MultiState' => {local => '14-local.conf', dir => '14-conf'},
};
use Catalyst::Test 'TestApp';

my $cfg = TestApp->cfg;

is($cfg->{dev}, 1);
is($cfg->{is_dev}, 1);
is($cfg->{host}, 'suka.com');
is($cfg->{www}, 'http://suka.com');
is($cfg->{suka_reg}, 'http://suka.com/reg');
is(TestApp->dev, 1);
