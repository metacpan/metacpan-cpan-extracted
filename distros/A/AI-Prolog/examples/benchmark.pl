#!/usr/local/bin/perl

use strict;
use warnings;
use lib ('../lib/', 'lib/');
use Benchmark;
use AI::Prolog;

my $prolog = AI::Prolog->new(benchmark());
my $t0 = new Benchmark;
for (1 .. 10) {
    $prolog->query('nrev30.');
    while (my $result = $prolog->results) {
        print $_,' ',@$result,$/;
    }
}
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "the code took:",timestr($td),"\n";

sub benchmark {
    return <<"    END_BENCHMARK";
    append([],X,X).
    append([X|Xs],Y,[X|Z]) :- 
        append(Xs,Y,Z). 
    nrev([],[]).
    nrev([X|Xs],Zs) :- 
        nrev(Xs,Ys), 
        append(Ys,[X],Zs). 
    nrev30 :- 
        nrev([1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0],X).
    END_BENCHMARK
}
