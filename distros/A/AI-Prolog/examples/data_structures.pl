#!/usr/local/bin/perl -l

use strict;
use warnings;
use lib ('../lib/', 'lib/');
use Data::Dumper;
$Data::Dumper::Indent = 0;

use AI::Prolog;

# note that the following line sets an experimental interface option
AI::Prolog->raw_results(0);
my $database = <<'END_PROLOG';
append([], X, X).
append([W|X],Y,[W|Z]) :- append(X,Y,Z).
END_PROLOG

my $logic = AI::Prolog->new($database);
$logic->query('append(LIST1,LIST2,[a,b,c,d]).');
while (my $result = $logic->results) {
    print Dumper($result->LIST1);
    print Dumper($result->LIST2);
}


AI::Prolog::Engine->raw_results(1);
$logic->query('append([X|Y],Z,[a,b,c,d]).');
while (my $result = $logic->results) {
    print Dumper($result);
}

# [HEAD|TAIL] syntax is buggy in queries with result object
#AI::Prolog::Engine->raw_results(0);
#$logic->query('append([X|Y],Z,[a,b,c,d]).');
#while (my $result = $logic->results) {
#    print Dumper($result->X);
#    print Dumper($result->Y);
#    print Dumper($result->Z);
#}

AI::Prolog::Engine->raw_results(0);
$logic = AI::Prolog->new(thief_prog());
$logic->query('steals(badguy, GOODS, VICTIM).');
while (my $result = $logic->results) {
    printf "badguy steals %s from %s\n"
        => $result->GOODS, $result->VICTIM;
}

AI::Prolog::Engine->raw_results(1);
$logic->query('steals(badguy, GOODS, VICTIM).');
while (my $result = $logic->results) {
    print Dumper($result);
}

sub thief_prog {
    return <<'    END_PROG';
    steals(PERP, STUFF, VICTIM) :-
        thief(PERP),
        valuable(STUFF),
        owns(VICTIM,STUFF),
        not(knows(PERP,VICTIM)).
    thief(badguy).
    valuable(gold).
    valuable(rubies).
    owns(merlyn,gold).
    owns(ovid,rubies).
    owns("Some rich person", gold).
    knows(badguy,merlyn).
    END_PROG
}
