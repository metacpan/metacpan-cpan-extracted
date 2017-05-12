#!/usr/bin/perl 
# http://xbean.cs.ccu.edu.tw/~dan/PL/PLTests/PLFinal2002.htm
# Write a Prolog program to schedule classes for a department of NG University.
# There are 6 class periods, 6-8pm and 8-10pm on Monday, Wednesday, and Friday
# evenings.   There are classrooms A, B, and C, and teachers Jim, Sally, Susan,
# and George.  There are classes algebra, geometry, calculus, and analysis, each
# of which has to be taught 2 class periods per week.  Jim can only come on
# Mondays.  Sally and Susan want to work together.   George can only teach the
# 6-8pm periods. Just write the program to print all possible schedules that meet
# these constraints; don?t try to solve the scheduling problem.

use strict;
use warnings;
use lib ('../lib/', 'lib/');

use aliased 'AI::Prolog';

my $prolog = Prolog->new(<<'END_PROLOG');
member(X,[X|Xs]).
member(X,[_|Ys]) :- member(X,Ys).

scheduler(L) :- makeList(L,4), different(L).

makeList([],0):- !.
makeList([course(Teacher,Time,Room)|Rest], N) :- 
    teacher(Teacher), 
    classtime(Time),
    classroom(Room), 
    is(M,minus(N,1)), 
    makeList(Rest,M).

teacher(jim).
teacher(sally).

classtime(afternoon).
classtime(evening).

classroom(X) :- member(X, [room1,room2]).

different([_]).
different([course(Teacher,Time,_)|Rest]) :- 
    member(course(Teacher,Time,_),Rest), 
    !, fail.
different([course(_,Time,Room)|T]) :- 
    member(course(_,Time,Room),T), !, fail.
different([_|T]) :- different(T).
END_PROLOG

use Data::Dumper;
$Data::Dumper::Indent = 0;
AI::Prolog::Engine->raw_results(1);
$prolog->query('scheduler(X)');
print Dumper $prolog->results; # there are more results.  We only need the one
