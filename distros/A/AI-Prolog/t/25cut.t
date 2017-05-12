#!/usr/bin/perl
# '$Id: 25cut.t,v 1.1 2005/02/20 18:27:55 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 27;
#use Test::More 'no_plan';

#XXX This is a bit annoying.  Term knows about its subclass, CUT,
# and this forces us to use Term before we use_ok($CLASS).
use aliased 'AI::Prolog::Term';
my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::Term::Cut';
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

ok my $cut = $CLASS->new(7), 'Calling it without arguments should succeed';
isa_ok $cut, $CLASS, '... and the object it returns';
isa_ok $cut, Term, '... and the object it returns';

can_ok $cut, 'functor';
is $cut->functor, '!', '... and its functor should always be a bang (!)';

can_ok $cut, 'arity';
is $cut->arity, 0, '... and a cut should always have an arity of zero';

can_ok $cut, 'args';
is_deeply $cut->args, [], '... and it should have no args';

can_ok $cut, 'bound';
ok $cut->bound, '... and a cut is always considered bound';

can_ok $cut, 'varid';
is $cut->varid, 7, '... and it should be whatever numeric value we pass to it';

can_ok $cut, 'deref';
is_deeply $cut->deref, $cut, '... and since it is bound, it returns $self';

can_ok $cut, 'ref';
ok ! defined $cut->ref, '... which means it should not reference anything';

can_ok $cut, 'to_string';
is $cut->to_string, 'Cut->7',
    '... and it should have an appropriate to_string representation';

can_ok $cut, 'dup';
my $cut2 = $cut->dup;
isnt $cut2, $cut, '... and duping a cut should not return the same cut';
is_deeply $cut2, $cut, '... but their values should be identical';
