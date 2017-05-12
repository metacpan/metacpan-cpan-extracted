#! perl

use Test::Simple tests => 2;

use Data::Dimensions;
Data::Dimensions::push_handler(\&Data::Dimensions::Map::parse_other);

ok(1, "setup handler");

my $one = Data::Dimensions->new({m=>1, s=>-1});
my $two = Data::Dimensions->new({m=>1, s=>-1});
my $bar = Data::Dimensions->new({__HONK_IF_YOU_PERL => 1});

$one->set = 1;
$two->set = 9;

$bar->set = $one + $two;

ok($bar == 1, "scaling works, didn't die badly");
