#!/usr/local/bin/perl -l

use strict;
use warnings;
use lib ('../lib/', 'lib/');

use aliased 'AI::Prolog';
AI::Prolog->raw_results(0); # experimental
my $logic = Prolog->new(thief_prog());
print "Without trace ...\n";
$logic->query('steals("Bad guy", STUFF, VICTIM)');
while (my $results = $logic->results) {
    printf "Bad guy steals %s from %s\n",
        $results->STUFF, $results->VICTIM;
}

print <<"END_MESSAGE";

The following will be a long trace of Prolog tries to satisfy the
above goal.

Hit Enter to begin.
END_MESSAGE
<STDIN>;

$logic->do('trace.');
$logic->query('steals("Bad guy", STUFF, VICTIM)');
while (my $results = $logic->results) {
    printf "Bad guy steals %s from %s\n",
        $results->STUFF, $results->VICTIM;
}

print <<"END_MESSAGE";

And we'll do it one more time, but this time calling notrace before
the query.

Hit Enter to begin.
END_MESSAGE
<STDIN>;

$logic->do('notrace.');
$logic->query('steals("Bad guy", STUFF, VICTIM)');
while (my $results = $logic->results) {
    printf "Bad guy steals %s from %s\n",
        $results->STUFF, $results->VICTIM;
}

sub thief_prog {
    return <<'    END_PROG';
    steals(PERP, STUFF, VICTIM) :-
        thief(PERP),
        valuable(STUFF),
        owns(VICTIM,STUFF),
        not(knows(PERP,VICTIM)).
    thief("Bad guy").
    valuable(gold).
    valuable(rubies).
    owns(merlyn,gold).
    owns(ovid,rubies).
    owns(kudra, gold).
    knows(badguy,merlyn).
    END_PROG
}
