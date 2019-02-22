#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use C::Mlock;
    my $ls = C::Mlock->new();
    ok( $ls, "Load uninitialised" );
    my $ps = $ls->pagesize();
    my $b = $ls->set_pages(1);
    ok( $ps eq $b, "Allocate one page" );
    my $i = $ls->initialize();
    ok( $b eq $i, "Initialize a page" );
    $ls = undef;
    $ls = C::Mlock->new(1);
    ok( $ls, "Load initialised" );
    $ls = undef;
}
