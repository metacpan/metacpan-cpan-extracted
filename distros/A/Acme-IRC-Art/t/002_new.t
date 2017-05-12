# -*- perl -*-

use Test::More tests => 2;
use Acme::IRC::Art;

my $art = Acme::IRC::Art->new(5,5);

is(join ('',$art->result),join ('',(" "x5," "x5," "x5," "x5," "x5)));

my $art2 = Acme::IRC::Art->new(3,5);

isnt(join ('',$art->result),join ('',$art2->result));

