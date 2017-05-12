#!/usr/local/bin/perl -l
use strict;
use warnings;
use lib ('../lib/', 'lib');
use aliased 'AI::Prolog';
use aliased 'AI::Prolog::Engine';

my $prolog = Prolog->new(<<'END_PROLOG');
append([], X, X).
append([W|X],Y,[W|Z]) :- append(X,Y,Z).
END_PROLOG

Engine->formatted(1);
$prolog->query('append(X,Y,[a,b,c,d]).');

print "Without a cut:\n";

while (my $result = $prolog->results) {
    print $result;
}

$prolog = Prolog->new(<<'END_PROLOG');
append([], X, X) :- !.   % note the cut operator
append([W|X],Y,[W|Z]) :- append(X,Y,Z).
END_PROLOG

print "\nWith a cut:\n";
$prolog->query('append(X,Y,[a,b,c,d]).');
while (my $result = $prolog->results) {
    print $result;
}
