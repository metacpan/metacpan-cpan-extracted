#!/usr/bin/perl
# '$Id: 25number.t,v 1.1 2005/02/20 18:27:55 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 34;
#use Test::More 'no_plan';

#XXX This is a bit annoying.  Term knows about its subclass, CUT,
# and this forces us to use Term before we use_ok($CLASS).
use aliased 'AI::Prolog::Term';
my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::Term::Number';
    use_ok($CLASS) or die;
}

# I hate the fact that they're interdependent.  That brings a 
# chicken and egg problem to squashing bugs.
use aliased 'AI::Prolog::Parser';

can_ok $CLASS, 'occurcheck';
is $CLASS->occurcheck, 0, '... and it should return a false value';
$CLASS->occurcheck(1);
is $CLASS->occurcheck, 1, '... but we should be able to set it to a true value';

can_ok $CLASS, 'new';

ok my $number = $CLASS->new(7), 'Calling it without arguments should succeed';
isa_ok $number, $CLASS, '... and the object it returns';
isa_ok $number, Term, '... and the object it returns';

can_ok $number, 'functor';
is $number->functor, '7', '... and its functor should always be the numeric value';

can_ok $number, 'arity';
is $number->arity, 0, '... and a number should always have an arity of zero';

can_ok $number, 'args';
is_deeply $number->args, [], '... and it should have no args';

can_ok $number, 'bound';
ok $number->bound, '... and a number is always considered bound';

can_ok $number, 'varid';
is $number->varid, 7, '... and it should be whatever numeric value we pass to it';

can_ok $number, 'deref';
is_deeply $number->deref, $number, '... and since it is bound, it returns $self';

can_ok $number, 'ref';
ok ! defined $number->ref, '... which means it should not reference anything';

can_ok $number, 'to_string';
is $number->to_string, '7',
    '... and it should have an appropriate to_string representation';

can_ok $number, 'value';
is $number->value, 7,
    '... and it should return an integer representing its value';

can_ok $number, 'dup';
my $number2 = $number->dup;
isnt $number2, $number, '... and duping a number should not return the same number';
is_deeply $number2, $number, '... but their values should be identical';

ok my $number3 = $CLASS->new, "Calling $CLASS->new() without an argument should succeed";
isa_ok $number3, $CLASS, '... and the object it returns';
ok $number3->bound, '... and it should still be bound';
ok defined $number3->value, '... and its value should be defined';
is $number3->value, '0', '... and it should have a value of zero';
