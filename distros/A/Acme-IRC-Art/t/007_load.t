# -*- perl -*-

use Test::More tests => 1;
use Acme::IRC::Art;

my $art = Acme::IRC::Art->new(5, 5);

$art->rectangle(0, 0, 4, 4, 5);
$art->save("t_test.aia");
$art->load("t_test.aia");

is_deeply([$art->result], [("\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5)]);

qx(rm t_test.aia);
