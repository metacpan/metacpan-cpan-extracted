#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 7;

BEGIN {
    use C::Mlock;
    my ($ls, $t, $rs, $s, $ps) = (undef, "Hello World!", "", 0, 0);
    $ls = C::Mlock->new(1);
    is( $ls->store($t, length($t)), 1, "Store Data" );
    $ps = $ls->pagesize();
    ok ($ps, "Get pagesize returned $ps");
    $s = $ls->set_size(13);
    is( $s, 13, "Set size to smaller");
    $s = $ls->set_pages(1);
    is ($s, $ps, "Set size to larger");
    $rs = $ls->get();
    is( $rs, $t, "Retrieve Data after changing the storage size" );
    $s = $ls->set_size(12);
    is( $s, 12, "Set size to smaller than store");
    $rs = $ls->get();
    is( $rs, "Hello World", "Get after truncate (returned: $rs)");
}
