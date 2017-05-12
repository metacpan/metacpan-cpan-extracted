#!/usr/local/bin/perl
use strict;
use warnings;
#use Test::More 'no_plan';
use Test::More tests => 6;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}

use lib '../lib/';
use aliased 'AI::Prolog';

my $prolog = Prolog->new(append_prog());
$prolog->query("append(X,Y,[a,b,c,d]).");
AI::Prolog::Engine->formatted(1);

is $prolog->results,  'append([], [a,b,c,d], [a,b,c,d])', 'Running the prolog should work';
is $prolog->results, 'append([a], [b,c,d], [a,b,c,d])', '... as should fetching more results';
is $prolog->results, 'append([a,b], [c,d], [a,b,c,d])', '... as should fetching more results';
is $prolog->results, 'append([a,b,c], [d], [a,b,c,d])', '... as should fetching more results';
is $prolog->results, 'append([a,b,c,d], [], [a,b,c,d])', '... as should fetching more results';
ok ! $prolog->results, '... and we should return false when we have no more results';

sub append_prog {
    "append([], X, X)."
   ."append([W|X],Y,[W|Z]) :- append(X,Y,Z).";
}
