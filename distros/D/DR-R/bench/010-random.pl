#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib t/lib);
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);

use Benchmark qw(:all);
use DR::R;

my $tree = new DR::R dimension => 2;

my $p;
for (my $i = 0; $i < 1_000_00; $i++) {
    $p = [ rand 100, rand 100, rand 100, rand 100 ];
    $tree->insert($p, $i);
}

my @LIST = (
    [ 'EQ'              => $p ],
    [ 'NEIGHBOR'        => [ 50, 50 ] ],
    [ 'CONTAINS'        => $p ],
    [ 'CONTAINS!'       => $p ],
    [ 'OVERLAPS'        => [ 50, 50 ] ],
    [ 'BELONGS'         => [ 20, 20, 80, 80 ] ],
    [ 'BELONGS!'        => [ 20, 20, 80, 80 ] ],
    [ 'ALL'             => [ 0, 0 ] ],

);

my %cmp_task;
for my $t (@LIST) {
    my $type = $t->[0];
    my $p = $t->[1];

    my $count = @{ $tree->select($type => $p, limit => 100) };
    die "Internal error" unless $count;


    $cmp_task{ $type } = sub {
            my $cnt = 0;
            $tree->foreach($type => $p, sub { ++$cnt < 100 });
    };
}

cmpthese 1_000_000, \%cmp_task;
