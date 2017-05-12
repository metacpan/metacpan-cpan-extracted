#!/usr/local/bin/perl -l
use strict;
use warnings;
use lib ('../lib/', 'lib');
use aliased 'AI::Prolog';

my $prolog = Prolog->new(<<'END_PROLOG');
member(X,[X|Xs]).
member(X,[_|Ys]) :- member(X,Ys).

teacher(Person) :- member(Person, [randal,bob,sally]).
classroom(Room) :- member(Room,   [class1,class2,class3]).
classtime(Time) :- member(Time,   [morning_day1,morning_day2,noon_day1,noon_day2]).
END_PROLOG

# note:  the other stuff in this example is part of a schedule
# demo that I'll be writing after a few more predicates
# are added

AI::Prolog::Engine->formatted(1);
$prolog->query('classroom(X).');

while (my $result = $prolog->results) {
    print $result;
}

$prolog->query('teacher(sally).');
while (my $result = $prolog->results) {
    print $result;
}
