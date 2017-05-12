#!/usr/local/bin/perl
use strict;
use warnings;
use lib ('../lib/', 'lib');
use Data::Dumper;
$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;

use AI::Prolog 0.64;
my $prolog = AI::Prolog->new(<<"END_PROLOG");
append([], X, X).
append([W|X], Y, [W|Z]) :- append(X, Y, Z).
END_PROLOG

print "Appending two lists 'append([a],[b,c,d],Z).'\n";
$prolog->query('append([a],[b,c,d],Z).');
while (my $result = $prolog->results) {
    print Dumper($result),"\n";
}

print "\nWhich lists appends to a known list to form another known list?\n'append(X,[b,c,d],[a,b,c,d]).'\n";
$prolog->query('append(X,[b,c,d],[a,b,c,d]).');
while (my $result = $prolog->results) {
    print Dumper($result),"\n";
}

print "\nWhich lists can be appended to form a given list?\n'append(X, Y, [foo, bar, 7, baz]).'\n";
my $list = $prolog->list(qw/foo bar 7 baz/);
$prolog->query("append(X,Y,[$list]).");
while (my $result = $prolog->results) {
    print Dumper($result),"\n";
}
