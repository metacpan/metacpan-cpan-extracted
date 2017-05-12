#!/usr/local/bin/perl 

# see http://www.compapp.dcu.ie/~alex/LOGIC/monkey.html
# This is the classic Monkey/Banana problem
use strict;
use warnings;
use lib ('../lib/', 'lib');
use AI::Prolog;

my $prolog = AI::Prolog->new(<<'END_PROLOG');
perform(grasp, 
        state(middle, middle, onbox, hasnot),
        state(middle, middle, onbox, has)).

perform(climb, 
        state(MP, BP, onfloor, H),
        state(MP, BP, onbox,   H)).

perform(push(P1,P2), 
        state(P1, P1, onfloor, H),
        state(P2, P2, onfloor, H)).

perform(walk(P1,P2), 
        state(P1, BP, onfloor, H),
        state(P2, BP, onfloor, H)).

getfood(state(_,_,_,has)).

getfood(S1) :- perform(Act, S1, S2),
              nl, print('In '), print(S1), print(' try '), print(Act), nl,
              getfood(S2).
END_PROLOG

$prolog->query("getfood(state(atdoor,atwindow,onfloor,hasnot)).");
$prolog->results; # note that everything is done internally.
                  # there's no need to process the results
