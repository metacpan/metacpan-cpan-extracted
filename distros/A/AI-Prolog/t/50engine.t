#!/usr/bin/perl
# '$Id: 50engine.t,v 1.10 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 35;

#use Test::More 'no_plan';
use Clone qw/clone/;

my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog::Engine';
    use_ok($CLASS) or die;
}

# I hate the fact that they're interdependent.  That brings a 
# chicken and egg problem to squashing bugs.
use aliased 'AI::Prolog::TermList';
use aliased 'AI::Prolog::Term';
use aliased 'AI::Prolog::Parser';

my $database = Parser->consult(<<'END_PROLOG');
append([], X, X).
append([W|X],Y,[W|Z]) :- append(X,Y,Z).
END_PROLOG
my @keys = sort keys %{$database->{ht}};
my @expected = qw{append/3};
is_deeply \@keys, \@expected,
    'A brand new database should only have the predicates listed in the query';

my $parser = Parser->new("append(X,Y,[a,b,c,d]).");
my $query  = $parser->_term;

can_ok $CLASS, 'new';
ok my $engine = $CLASS->new($query, $database),
    '... and calling new with a valid query and database should succeed';
isa_ok $engine, $CLASS, '... and the object it returns';

@expected = qw{
    !/0
    append/3
    assert/1
    call/1
    consult/1
    eq/2
    fail/0
    ge/2
    gensym/1
    gt/2
    halt/0
    help/0
    help/1
    if/3
    is/2
    le/2
    listing/0
    listing/1
    lt/2
    ne/2
    nl/0
    not/1
    notrace/0
    once/1
    or/2
    perlcall2/2
    print/1
    println/1
    retract/1
    trace/0
    true/0
    var/1
    wprologcase/3
    wprologtest/2
    write/1
    writeln/1
};

@keys = sort keys %{$database->ht};
is_deeply \@keys, \@expected,
    '... and the basic prolog terms should be bootstrapped';
can_ok $engine, 'results';
is $engine->results, 'append([], [a,b,c,d], [a,b,c,d])',
    '... calling it the first time should provide the first unification';
is $engine->results, 'append([a], [b,c,d], [a,b,c,d])',
    '... and then the second unification';
is $engine->results, 'append([a,b], [c,d], [a,b,c,d])',
    '... and then the third unification';
is $engine->results, 'append([a,b,c], [d], [a,b,c,d])',
    '... and then the fifth unification';
is $engine->results, 'append([a,b,c,d], [], [a,b,c,d])',
    '... and then the last unification unification';
ok ! defined $engine->results,
    '... and it should return undef when there are no more results';

my $bootstrapped_db = clone($database);

$query = Term->new('append(X,[d],[a,b,c,d]).');
can_ok $engine, 'query';
$engine->query($query);
is $engine->results,'append([a,b,c], [d], [a,b,c,d])',
    '... and it should let us issue a new query against the same db';
ok !$engine->results, '... and it should not return spurious results';

# this will eventually test data structures

can_ok $CLASS, 'formatted';

$engine->formatted(0);
$engine->query(Term->new('append(X,Y,[a,b,c,d])'));
my $result = $engine->results;
is_deeply $result->X, [], '... and the X result should be correct';
is_deeply $result->Y, [qw/a b c d/], '... and the Y result should be correct';

$result = $engine->results;
is_deeply $result->X, [qw/a/], '... and the X result should be correct';
is_deeply $result->Y, [qw/b c d/], '... and the Y result should be correct';

$result = $engine->results;
is_deeply $result->X, [qw/a b/], '... and the X result should be correct';
is_deeply $result->Y, [qw/c d/], '... and the Y result should be correct';

$result = $engine->results;
is_deeply $result->X, [qw/a b c/], '... and the X result should be correct';
is_deeply $result->Y, [qw/d/], '... and the Y result should be correct';

$result = $engine->results;
is_deeply $result->X, [qw/a b c d/], '... and the X result should be correct';
is_deeply $result->Y, [], '... and the Y result should be correct';

ok ! defined ($result = $engine->results),
    '... and results() should return undef when there are no more results';

can_ok $CLASS, 'raw_results';
$CLASS->raw_results(1);
$CLASS->formatted(0);
$engine->query(Term->new('append(X,Y,[a,b,c,d])'));
is_deeply $engine->results, ['append', [], [qw/a b c d/], [qw/a b c d/]],
    '... and subsequent results should match expectations';
is_deeply $engine->results, ['append', [qw/a/], [qw/b c d/], [qw/a b c d/]],
    '... and subsequent results should match expectations';
is_deeply $engine->results, ['append', [qw/a b/], [qw/c d/], [qw/a b c d/]],
    '... and subsequent results should match expectations';
is_deeply $engine->results, ['append', [qw/a b c/], [qw/d/], [qw/a b c d/]],
    '... and subsequent results should match expectations';
is_deeply $engine->results, ['append', [qw/a b c d/], [], [qw/a b c d/]],
    '... and subsequent results should match expectations';
ok ! defined $engine->results,
    '... and it should return undef when there are no more results'
