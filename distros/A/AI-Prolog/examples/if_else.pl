#!/usr/local/bin/perl -l
use strict;
use lib qw(../lib/ lib/);
use AI::Prolog;
use Data::Dumper;
$Data::Dumper::Terse = 1;

my $prolog = AI::Prolog->new(<<'END_PROLOG');
thief(badguy).
steals(PERP, X) :-
 if(thief(PERP), eq(X,rubies), eq(X,nothing)).
END_PROLOG
$prolog->query("steals(badguy,X).");
print Dumper $prolog->results;

$prolog->query("steals(ovid, X).");
print Dumper $prolog->results;
