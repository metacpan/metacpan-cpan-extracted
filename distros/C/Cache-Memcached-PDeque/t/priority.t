#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More;

my $items = 777;
my $priorities = 7;

plan tests => $items;

my $dq = Cache::Memcached::PDeque->new( name => 'priority', max_prio => $priorities, prioritizer => \&remainder );

sub remainder {
    my $element = shift;
    my $prio = 1 + ($element % $priorities );
    return $prio;
}

my %by_prio;

foreach my $i ( 1 .. $items ) {
    $dq->push($i);
    my $prio = remainder($i);
    push @{$by_prio{$prio}}, $i;
}

my @expected;
for( my $p = $priorities; $p>=1; $p-- ) {
    push @expected, @{$by_prio{$p}};
}

while ( $dq->size ) {
    my $expect = shift @expected;
    is $dq->shift, $expect, "Expecting $expect" ;
}

$dq->_flush;