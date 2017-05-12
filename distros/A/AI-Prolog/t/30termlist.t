#!/usr/bin/perl
# '$Id: 30termlist.t,v 1.3 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
#use Test::More 'no_plan';
use Test::More tests => 14;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::TermList';
    use_ok($CLASS) or die;
}

# I hate the fact that they're interdependent.  That brings a 
# chickin and egg problem to squashing bugs.
use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::Term';

can_ok $CLASS, 'new';
my $parser = Parser->new("p(X,p(X,Y)).");
ok my $tls = $parser->_termlist,
    '... we should be able to create a termlist from the parser';
isa_ok $tls, $CLASS, '... and the object it creates';

can_ok $tls, 'to_string';
is $tls->to_string, "\n\tp(A, p(A, B))",
    '... and its to_string representation should be correct';

can_ok $tls, 'term';
ok my $term = $tls->term, '... and calling it should succeed';
isa_ok $term, Term, '... and the object it returns';
is $term->functor, 'p', '... and it should have the correct functor';
is $term->arity, 2, '... and the correct arity';

my $db = Parser->consult('p(this,that).');
can_ok $tls, 'resolve';
$tls->resolve($db);
is $tls->to_string, "\n\tp(A, p(A, B))",
    '... and its to_string representation should reflect this';

$db = Parser->consult('p(this,that).');
$tls = Parser->new('p(X,p(X,Y)).')->_termlist;
#$tls->{definer}[0] = 'anything';
$tls->resolve($db);

$tls = Parser->new(<<'END_PROLOG')->_termlist;
father(john, sally).
girl(sally).
daughter(X) :-
  girl(X),
  father(ANYONE, X).
END_PROLOG
is $tls->to_string, "\n\tfather(john, sally)",
    'Building a complex termlist should succeed';
