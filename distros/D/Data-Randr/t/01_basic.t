use strict;
use warnings;
use Test::More;

use Data::Randr qw/randr/;

my $COUNT = 10000;

{
    for my $number (1..$COUNT) {
        my $res = randr(1, 1);
        fail("randr(1, 1): $res") if $res != 1;
    }

    for my $number (1..$COUNT) {
        my $res = randr(1, 100);
        fail("randr(1, 100): $res") if $res < 0 || $res > 2;
    }

    for my $number (1..$COUNT) {
        my $res = randr(10);
        fail("randr(10, 10): $res") if $res < 9 || $res > 11;
    }

    for my $number (1..$COUNT) {
        my $res = randr(100);
        fail("randr(100, 10): $res") if $res < 90 || $res > 110;
    }

    for my $number (1..$COUNT) {
        my $res = randr(100, 10, 2);
        fail("randr(100, 10, 2): $res") if $res < 90 || $res > 110;
    }

    ok 1;
}

{
    my $r = Data::Randr->new(rate => 10);
    for my $number (1..$COUNT) {
        my $res = $r->randr(10);
        fail("\$r->randr(10): $res") if $res < 9 || $res > 11;
    }

    ok 1;
}

{
    my $r = Data::Randr->new(rate => 10);
    for my $number (1..$COUNT) {
        my $res = $r->randr(10, 20);
        fail("\$r->randr(10, 20): $res") if $res < 8 || $res > 12;
    }

    ok 1;
}

{
    my $r = Data::Randr->new(rate => 10);
    for my $number (1..$COUNT) {
        my $res = $r->randr(10, 20, 2);
        fail("\$r->randr(10, 20): $res") if $res < 8 || $res > 12;
    }

    ok 1;
}

{
    my $r = Data::Randr->new(rate => 20, digit => 2);
    for my $number (1..$COUNT) {
        my $res = $r->randr(10);
        fail("\$r->randr(10): $res") if $res < 8 || $res > 12 || $res !~ m!\.\d\d!;
    }

    ok 1;
}

done_testing;
