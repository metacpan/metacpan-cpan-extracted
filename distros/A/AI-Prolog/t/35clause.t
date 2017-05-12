#!/usr/bin/perl
# '$Id: 35clause.t,v 1.2 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
#use Test::More 'no_plan';
use Test::More tests => 14;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::TermList::Clause';
    use_ok($CLASS) or die;
}

# I hate the fact that they're interdependent.  That brings a 
# chickin and egg problem to squashing bugs.
use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::Term';

can_ok $CLASS, 'new';
my $termlist = Parser->new("p(X,p(X,Y)).")->_termlist;
ok my $clause = $CLASS->new($termlist->term, $termlist->next),
    '... and creating a new clause from a parser object should succeed';
isa_ok $clause, $CLASS, '... and the object it creates';

can_ok $clause, 'to_string';
is $clause->to_string, 'p(A, p(A, B)) :- null',
    '... and its to_string representation should be correct';

can_ok $clause, 'term';
ok my $term = $clause->term, '... and calling it should succeed';
isa_ok $term, Term, '... and the object it returns';
is $term->functor, 'p', '... and it should have the correct functor';
is $term->arity, 2, '... and the correct arity';

my $db = Parser->consult('p(this,that).');
can_ok $clause, 'resolve';
$clause->resolve($db);
is $clause->to_string, 'p(A, p(A, B)) :- null',
    '... and its to_string representation should reflect this';

$db = Parser->consult('p(this,that).');
$termlist = Parser->new('p(X,p(X,Y)).')->_termlist;
#$termlist->{definer}[0] = 'anything';
$termlist->resolve($db);

$termlist = Parser->new(<<"END_PROLOG")->_termlist;
father(Parent, Child) :-
  male(Parent),
  parent(Parent, Child).
END_PROLOG
$clause = $CLASS->new($termlist->term, $termlist->next);
is $clause->to_string, "father(A, B) :- \n\tmale(A),\n\tparent(A, B)",
    'Building a complex clause should succeed';
