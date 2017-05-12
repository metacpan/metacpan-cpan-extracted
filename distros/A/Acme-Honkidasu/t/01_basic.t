#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;

use Test::More tests => 84;

use Acme::Honkidasu;

for my $i (1..12) {
    my $t = Time::Piece->strptime(sprintf('%02d', $i), '%m');
    chomp( my $honki = $Acme::Honkidasu::LIST_HONKIDASU->[ $i - 1 ] );
    cmp_ok $t->honkidasu, 'eq', $honki;
    cmp_ok $t->strftime('%('), 'eq', $honki;
    cmp_ok $t->strftime('%%(%%%'), 'eq', '%(%%';
    cmp_ok $t->strftime('%%%(%%%'), 'eq', "%$honki%%";
    cmp_ok $t->strftime('%%%(%%%%(%%%'), 'eq', "%$honki%%(%%";

    chomp( my $honki_positive = $Acme::Honkidasu::LIST_HONKIDASU_POSITIVE->[ $i - 1 ] );
    cmp_ok $t->honkidasu(1), 'eq', $honki_positive;
    cmp_ok $t->strftime('%)'), 'eq', $honki_positive;
}

my $now = localtime;
diag sprintf("【%d月】%s", $now->mon, $now->honkidasu);
