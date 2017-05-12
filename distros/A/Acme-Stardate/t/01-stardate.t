#!perl -T

use Test::More tests => 3;

use Acme::Stardate 'stardate';

$x = stardate;
sleep 1;
$y = stardate;

ok($x, "returns");
ok($x =~ /^\d+\.\d+$/, "numeric");
ok( $y > $x, "ordinal");
