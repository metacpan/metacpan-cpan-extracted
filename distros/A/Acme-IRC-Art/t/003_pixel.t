# -*- perl -*-

use Test::More tests => 7;
use Acme::IRC::Art;

my $art = Acme::IRC::Art->new(5,5);

$art->pixel(0,0,5);
is_deeply([$art->result],[("\0035,5 \003    "," "x5," "x5," "x5," "x5)]);

$art->pixel(0,0,5,1);
is_deeply([$art->result],[("\0035,5 \003    "," "x5," "x5," "x5," "x5)]);

$art->pixel(0,0,5,-1);
is_deeply([$art->result],[(" "x5," "x5," "x5," "x5," "x5)]);

$art->pixel([0,1,2],[0,1,2],5);
is_deeply([$art->result],[("\0035,5 \003    "," \0035,5 \003"." "x3,"  \0035,5 \003  "," "x5," "x5)]);

$art->pixel([0,1,2],[0,1,2],5,-1);
is_deeply([$art->result],[(" "x5," "x5," "x5," "x5," "x5)]);

$art->pixel(0,0,5);
$art->pixel(1,1,5);
$art->pixel(2,2,5);
is_deeply([$art->result],[("\0035,5 \003    "," \0035,5 \003"." "x3,"  \0035,5 \003  "," "x5," "x5)]);

$art->pixel(0,0,5,-1);
$art->pixel(1,1,5,-1);
$art->pixel(2,2,5,-1);
is_deeply([$art->result],[(" "x5," "x5," "x5," "x5," "x5)]);
