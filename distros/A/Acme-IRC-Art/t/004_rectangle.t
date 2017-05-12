# -*- perl -*-

use Test::More tests => 4;
use Acme::IRC::Art;

my $art = Acme::IRC::Art->new(5,5);

$art->rectangle(0,0,4,4,5);
is_deeply([$art->result],[("\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5)]);

$art->rectangle(0,0,4,4,5,-1);
is_deeply([$art->result],[(" "x5," "x5," "x5," "x5," "x5)]);

$art->rectangle(0,0,2,2,5);
$art->rectangle(0,0,4,4,5,1);
is_deeply([$art->result],[("\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5)]);

$art->rectangle(0,0,4,4,5,-1);
is_deeply([$art->result],[(" "x5," "x5," "x5," "x5," "x5)]);

