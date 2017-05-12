#!/usr/bin/perl
# '$Id: 99regression.t,v 1.4 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
use Test::More;
BEGIN {
eval q{use Test::MockModule};
if ($@) {
    plan skip_all => "Test::MockModule, Test::Exception required for this";
} else {
    plan tests => 5;
}
}
#use Test::More qw/no_plan/;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}
use aliased 'AI::Prolog';
use aliased 'AI::Prolog::Engine';

Engine->formatted(1);
my $prolog = Prolog->new(<<'END_PROLOG');
i_am_at(top).
down :- retract(i_am_at(top)),assert(i_am_at(bottom)).
END_PROLOG

$prolog->query('down.');
is $prolog->results, 'down', 'retract/1 should succeed';
$prolog->query('i_am_at(X)');
is $prolog->results, 'i_am_at(bottom)', '... and the goal should be retracted';
ok ! $prolog->results, '... and we should not have spurious results';

$prolog = Prolog->new(<<'END_PROLOG');
    member_of(X, [X|_]).
    member_of(X, [_|Tail]) :-
        member_of(X, Tail).

    balls([a,b,c]).

    no_intersect([], _).
    no_intersect([Head|Tail], List) :-
        not(member_of(Head, List)),
        no_intersect(Tail, List).

    unique([]).
    unique([Head|Tail]) :-
        no_intersect([Head], Tail),
        unique(Tail).

    set_of_balls(A,B) :-
        balls(Balls),
        member_of(A, Balls),
        member_of(B, Balls),
        unique([A,B]).
END_PROLOG
$prolog->query('set_of_balls(X,Y).');
my @results;
Engine->formatted(0);
while (my $results = $prolog->results) {
    push @results => [@{$results}[1,2]];
}
my @expected = (
  [ 'a', 'b' ],
  [ 'a', 'c' ],
  [ 'b', 'a' ],
  [ 'b', 'c' ],
  [ 'c', 'a' ],
  [ 'c', 'b' ]
);
is_deeply \@results, \@expected, 'The .62 unify bug should be bye-bye';

my $faux_engine = Test::MockModule->new(Engine);
my @stdout;
$faux_engine->mock(_warn => sub { push @stdout => @_ });
$prolog->query('no_such_predicate(X).');
$prolog->results;
like $stdout[0], qr{WARNING:  undefined predicate \(no_such_predicate/1\)},
    'Non-existent predicates should warn';
