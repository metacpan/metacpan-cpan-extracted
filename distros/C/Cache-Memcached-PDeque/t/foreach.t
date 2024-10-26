#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More;

my $dq = Cache::Memcached::PDeque->new( name => 'foreach', max_prio => 1 );
my @list = ( 1..10 );
plan tests => scalar @list;

sub do_something {
    my $el = shift;
    print "square of $el is " . $el ** 2 . "\n";
    is $el, shift @list;
}

foreach my $i ( @list ) {
    print "Push:$i\n";
    $dq->push($i);
}

$dq->foreach(\&do_something);

$dq->_flush;
