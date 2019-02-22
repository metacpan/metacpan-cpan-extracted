#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use C::Mlock;
    my ($ls, $t, $rs) = (undef, "Hello World!", "");
    $ls = C::Mlock->new(1);
    is( $ls->store($t, length($t)), 1, "Store Data" );
    $rs = $ls->get();
    is( $rs, $t, "Retrieve Data" );
}
