#! perl

use Test::Simple tests => 6;

use Data::Dimensions;

ok(1, "loaded");

my $one = Data::Dimensions->new({m=>1});
my $two = Data::Dimensions->new({m=>1});
my $tee = Data::Dimensions->new({m=>1});

$one->set = 3;
$two->set = 4;

$tee->set = $one + $two;

ok($tee == 7, "simple addition");

my $fee = Data::Dimensions->new({m=>2});

$fee = $one * $two;

ok($fee == 12, "multiply");

$tee = $fee / $two;

ok($tee == 3, "divide");

eval {
    my $return = $fee + $one;
};
ok($@, "mixing types dies");

eval {
    $fee->set = $one;
};
ok($@, "saving incorrectly dies");
