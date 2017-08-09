#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Test::More tests    => 11;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::R';
}


isa_ok(DR::R->new, DR::R::, 'instance created');
is(DR::R->new->dimension, 2, 'default dimension is 2');
is(DR::R->new(dimension => 5)->dimension, 5, 'dimension 5');

for my $r (DR::R->new) {
    my %inserted;
    for (1 .. 100) {
        my ($x, $y) = (20 + rand 10, 20 + rand 10);
        my $id = $r->insert([$x, $y], [ $x, $y ]);
        $inserted{$id}++;
        ($x, $y) = (rand 10, rand 10);
        $id = $r->insert([$x, $y, $x, $y], [ $x, $y ]);
        $inserted{$id}++;
    }

    is keys(%inserted), 200, 'all insterted tuples has unique id';

    my ($belongs, $belongs_strict) = (0, 0);
    my $found = 0;
    $r->foreach('BELONGS', [0, 0, 10, 10], sub {
        $found++ if exists $inserted{$_[1]};
        ++$belongs;
        return;
    });

    is $found, 100, 'found all ids';
    
    $r->foreach('BELONGS!', [0, 0, 10, 10], sub {
        ++$belongs_strict;
        return;
    });

    is $belongs, 100, 'BELONGS';
    cmp_ok $belongs_strict, '<=', $belongs, 'BELONGS! <';
    ok $belongs, 'BELONGS! >';

    
    my @dist;
    $r->foreach('NEIGHBOR', [5, 5], sub {
        my ($p) = @_; 
        
        my $dist = (5 - $p->[0]) ** 2 + (5 - $p->[1]) ** 2;
        push @dist => $dist;
        return;
    });

    my $errors = 0;
    is @dist, 200, 'all points';

    for (0 .. $#dist - 1) {
        $errors ++ if $dist[$_] > $dist[$_ + 1];
    }

    cmp_ok $errors, '<=', 5, 'order by dist';
}

