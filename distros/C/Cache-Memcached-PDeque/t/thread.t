#!/usr/bin/perl

BEGIN { unshift @INC, 'lib'; }

use Cache::Memcached::PDeque;
use Data::Dump qw(dd quote pp);
use Test::More;
use threads;


my $items = 100;
my $children = 10;
my $priorities = 1;

my $dq = Cache::Memcached::PDeque->new( name => 'fork', max_prio => $priorities );

plan tests => $children;

sub child {
    my $tid = threads->tid();

    print "$tid:Started\n";

    foreach my $i ( 1 .. $items ) {
        $dq->push("$tid:$i");
        print "$tid:Pushed:$i\n";
    }

    my $accepted = 0;

    while ( $accepted < $items ) {
        my $item = $dq->shift;
        my ( $id ) = $item =~ /^(\d+):\d+$/;
        if ( $tid != $id ) {
            print "$tid:Pushback:$item\n";
            $dq->push($item);
        } else {
            print "$tid:Accepted:$item\n";
            $accepted++;
        }
        threads->yield();
    }
    print "$tid:Stopped\n";
    return $accepted;
}

foreach my $i ( 1 .. $children ) {

    # If we call threads->create() in void context, the return
    # value cannot be captured with join()!!!
    my $thr = threads->create(\&child);
}

do {

    #print '.';

    my @joinable = threads->list(threads::joinable);
    foreach my $thr ( @joinable ) {
        my $tid = $thr->tid();
        print "$tid:Joined\n";
        my $rc = $thr->join();
        is $rc, $items;
    }

    # sleep 1; # feeling lazy today...
} while ( threads->list() );
