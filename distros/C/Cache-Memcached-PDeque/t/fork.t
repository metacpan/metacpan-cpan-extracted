#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More;

my $items = 100;
my $children = 10;
my $priorities = 1;

plan tests => $children;

sub child {
    print "$$:Started\n";

    my $dq = Cache::Memcached::PDeque->new( name => 'fork', max_prio => $priorities );

    foreach my $i ( 1 .. $items ) {
        $dq->push("$$:$i");
        print "$$:Pushed:$i\n";
    }

    my $accepted = 0;

    while ( $accepted < $items ) {
        my $item = $dq->shift;
        my ( $pid ) = $item =~ /^(\d+):\d+$/;
        if ( $$ != $pid ) {
            print "$$:Pushback:$item\n";
            $dq->push($item);
        } else {
            print "$$:Accepted:$item\n";
            $accepted++;
        }
    }
    print "$$:Stopped\n";
    return $accepted;
}

foreach my $i ( 1 .. $children ) {

    my $pid = fork();

    if ( 0 == $pid ) {
        # child running
        exit child();
    }
}

while ( $children ) {
    my $pid = waitpid -1, 0;
    next unless $pid>0;
    my $rc = $?>>8;
    is $rc, $items;
    $children--;
}
