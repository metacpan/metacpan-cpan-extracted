#!/usr/bin/perl
# '$Id: 80preprocessor.t,v 1.2 2005/06/20 07:36:48 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 8;
#use Test::More qw/no_plan/;
use aliased 'AI::Prolog';

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::Parser::PreProcessor';
    use_ok($CLASS) or die;
}

can_ok $CLASS, 'process';
is $CLASS->process('foo.'), 'foo.', '... and it should return standard Prolog unchanged.';

my $prolog = <<END_PROLOG;
factorial(N,F) :-
    N > 0,
    N1 is N-1,
    factorial(N1,F1), 
    F is N*F1.
factorial(0,1). 
END_PROLOG

my $expected = <<END_PROLOG;
factorial(N,F) :-
    gt(N, 0),
    is(N1, minus(N, 1)),
    factorial(N1,F1), 
    is(F, mult(N, F1)).
factorial(0,1). 
END_PROLOG
is $CLASS->process($prolog), $expected,
    '... and math expressions should be transformed correctly';

my $prog = Prolog->new($prolog);
$prog->query('factorial(5,X).');
my $result = $prog->results;
is $result->[2], 120, '... and we can use pre-processed programs';

$prolog   = 'bar(X) :- 3 \= X.';
$expected = 'bar(X) :- ne(3, X).';
is $CLASS->process($prolog), $expected,
    '... and math expressions should be transformed correctly';
$prog = Prolog->new($prolog);
$prog->query('bar(2).');
$result = $prog->results;
is $result->[1], 2, '... and we can use pre-processed programs';

$prog->query('bar(3).');
$result = $prog->results;
ok ! $result, '... and we can use pre-processed programs';
