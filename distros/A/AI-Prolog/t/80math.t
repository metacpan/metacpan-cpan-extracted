#!/usr/bin/perl
# '$Id: 80math.t,v 1.5 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 31;

#use Test::More qw/no_plan/;
use Clone qw/clone/;

BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}
use aliased 'AI::Prolog';
use aliased 'AI::Prolog::Engine';
use aliased 'AI::Prolog::KnowledgeBase';
#
# Math
#

Engine->formatted(1);
my $prolog = Prolog->new(<<'END_PROLOG');
value(rubies, 100).
value(paper, 1).
thief(badguy).
steals(PERP, STUFF) :-
    value(STUFF, DOLLARS),
    gt(DOLLARS, 50).
END_PROLOG

$prolog->query('is(X,7)');
is $prolog->results, 'is(7, 7)', 'is/2 should be able to bind a term to a var';

$prolog->query('is(X,-7)');
is $prolog->results, 'is(-7, -7)', '... and it should handle negative numbers';

$prolog->query('is(X,.7)');
is $prolog->results, 'is(.7, .7)', '... and number which begin with decimal points';

$prolog->query('is(X,-.7)');
is $prolog->results, 'is(-.7, -.7)', '... and negative numbers with decimal points';

$prolog->query('is(7,X)');
eval {$prolog->results};
like $@, qr/Tried to to get value of unbound term \(A\)/,
    '... but trying to call is(7,X) with an unbound rhs should die';

$prolog->query('is(7,7)');
is $prolog->results, 'is(7, 7)', '... but it should succeed if both terms are bound and equal';

$prolog->query('is(5,7)');
ok ! defined $prolog->results, '... and it should fail if both terms are bound but unequal';

$prolog->query('gt(4,3)');
is $prolog->results, 'gt(4, 3)',
    'gt(X,Y) should succeed if the first argument > the second argument.';

$prolog->query('gt(3,34)');
ok ! $prolog->results,
    '... and it should fail if the first argument < the second argument.';

$prolog->query('gt(3,3)');
ok ! $prolog->results,
    '... and it should fail if the first argument = the second argument.';
    
$prolog->query('steals(badguy, X)');
is $prolog->results, 'steals(badguy, rubies)',
    '... and it should succeed as part of a complicated query';
ok ! $prolog->results, '... but it should not return more than the correct results';

$prolog->query('ge(4,3)');
is $prolog->results, 'ge(4, 3)',
    'ge(X,Y) should succeed if the first argument > the second argument.';

$prolog->query('ge(3,34)');
ok ! $prolog->results,
    '... and it should fail if the first argument < the second argument.';

$prolog->query('ge(3,3)');
is $prolog->results, 'ge(3, 3)',
    '... and it should succeed if the first argument = the second argument.';
    
$prolog->query('lt(3,4)');
is $prolog->results, 'lt(3, 4)',
    'lt(X,Y) should succeed if the first argument < the second argument.';

$prolog->query('lt(34,3)');
ok ! $prolog->results,
    '... and it should fail if the first argument < the second argument.';

$prolog->query('lt(3,3)');
ok ! $prolog->results,
    '... and it should fail if the first argument = the second argument.';

$prolog->query('le(3,4)');
is $prolog->results, 'le(3, 4)',
    'le(X,Y) should succeed if the first argument < the second argument.';

$prolog->query('le(34,3)');
ok ! $prolog->results,
    '... and it should fail if the first argument < the second argument.';

$prolog->query('le(3,3)');
is $prolog->results, 'le(3, 3)',
    '... and it should succeed if the first argument = the second argument.';

$prolog->query('is(X,plus(3,4))');
is $prolog->results, 'is(7, plus(3, 4))', 'plus/2 should succeed';

$prolog->query('is(X,plus(3,-4))');
is $prolog->results, 'is(-1, plus(3, -4))', '... even with negative values';

$prolog->query('is(X,plus(3,plus(-2,4)))');
is $prolog->results, 'is(5, plus(3, plus(-2, 4)))', '... or complicated math';

$prolog->query('is(X,minus(3,4))');
is $prolog->results, 'is(-1, minus(3, 4))', 'minus/2 should succeed';

$prolog->query('is(X,mult(3,4))');
is $prolog->results, 'is(12, mult(3, 4))', 'mult/2 should succeed';

$prolog->query('is(X,div(12,3))');
is $prolog->results, 'is(4, div(12, 3))', 'div/2 should succeed';

$prolog->query('is(X,mod(12,5))');
is $prolog->results, 'is(2, mod(12, 5))', 'mod/2 should succeed';

$prolog->query('is(X,pow(3,2))');
is $prolog->results, 'is(9, pow(3, 2))','pow/2 should succeed';

$prolog->query('is(X,pow(16,.5))');
is $prolog->results, 'is(4, pow(16, .5))','... even with a real exponent';

$prolog->query('is(X,pow(16,-1))');
is $prolog->results, 'is(0.0625, pow(16, -1))','... or a negative one';
