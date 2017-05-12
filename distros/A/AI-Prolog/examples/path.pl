#!/usr/local/bin/perl -l
use strict;
use warnings;
use lib ('../lib/', 'lib');
use AI::Prolog;
use Benchmark;
use Data::Dumper;
$Data::Dumper::Indent = 0;

my $query = shift || 2;
my $prolog = AI::Prolog->new(path_prog());

$prolog->query('solve( Dest, L).')   if $query == 1;
$prolog->query('solve( p(8,8), L).') if $query == 2; 
$prolog->query('solve( p(2,2), L).') if $query == 3;

my $t0 = new Benchmark;
#$prolog->trace(1);
my $results = $prolog->results;
print Dumper($results);
my $t1 = new Benchmark;
my $td = timediff($t1, $t0);
print "the code took:",timestr($td),"\n";

sub path_prog {
    return <<'    END_PROG';
    solve(Dest,L) :- 
       solve(p(1,1), Dest, L).
    solve(S, Dest, Sol) :-
        path(S, Dest, [S], Path),
        invert(Path, Sol).

    path( P,  P,  L,  L).
    path( Node, Goal, Path, Sol) :- 
        arc( Node, Node2),  not( wall(Node2) ),
        not( member( Node2, Path)),
        path( Node2, Goal, [Node2 | Path], Sol).

    arc( p(X,Y), p(X1,Y) ) :- suc(X,X1).
    arc( p(X,Y), p(X1,Y) ) :- suc(X1,X).
    arc( p(X,Y), p(X,Y1) ) :- suc(Y,Y1).
    arc( p(X,Y), p(X,Y1) ) :- suc(Y1,Y).

    wall( p(3,2) ).
    wall( p(3,3) ).
    wall( p(3,4) ).
    wall( p(5,3) ).
        
    suc(1,2).
    suc(2,3).
    suc(3,4).
    suc(4,5).
    suc(5,6).
    suc(6,7).
    suc(7,8).
        
    invert(IN, OUT) :- invert1(IN,[],OUT).

    invert1([], L,L).
    invert1( [A | Tail], L,Res) :-
        invert1( Tail, [A | L], Res).

    member(X, [X|Y]).
    member(X, [A|B]) :- member(X,B).
    END_PROG
}
