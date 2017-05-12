#!/usr/bin/perl
# '$Id: 50engine.t,v 1.10 2005/08/06 23:28:40 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 6;

my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'AI::Prolog';
    use_ok($CLASS) or die;
}

my $p = $CLASS->new(<<END_PROLOG);
foo(X, [1,2,3,4]).
END_PROLOG

$p->raw_results(0);

$p->query('foo(1,[X,Y|Z])');

ok my $r = $p->results(), 'Got results from query';

is $r->X(), 1, 'Head of result list is ok';

is $r->Y(), 2, 'Next element in result list is ok';

is_deeply $r->Z(), [3,4], 'Tail of result list is ok';

ok ! defined $p->results(), '... and there should be no more results';
