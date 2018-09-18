#!perl

use strict;
use warnings;
use v5.8;
use lib './../lib';
use DFA::Simple;

#A table of what to do when entering or leaving a state.
my $Transitions =[
 #Say "Intro" when entering state; do nothing when leaving
     [sub {print "Intro\n";}, undef],

 #Say "Greetings" when entering state, do nothing when leaving
     [sub {print "Greetings\n";}, undef],

 #When entering, do nothing, when leaving do nothing
     [undef,undef],

 #When entering say "Bye", when leaving do nothing
     [sub {print "Bye\n";}, undef],
];


# A global variable
my $BogusTest=0;

# Our state table.  
my $States =[
  #State #0
   [
 #Next State,  Test that must be true or return true if we are to go
 #into that state, what we do while /in/ that state
 [1, sub{$BogusTest}, sub{print "Am Here (in state 1)\n"}],

 #We can't go to any other state
   ],

  #State 1
   [
 # We can go to state #2 from state #1 if the test succeeds, but we
 # don't really do anything there
 [2, sub{$BogusTest}, ],
   ],

  #State 2
   [
 #We can go to state #1 again, but we do nothing
 [1, sub{$BogusTest}, ],

 # If the above test(s) fail, the undef below will force us to go
 # into state #3
 [3, undef, sub {print "Am Here (in state 3)\n";}],
   ],
  ];

my $F=new DFA::Simple $Transitions, $States;
$F->State(0);

print "\nI will force us to silently go to state 1, then 2, then 3:\n";
$BogusTest=1;
#Drive the state machine thru one transition
$F->Check_For_NextState();
#Drive the state machine thru one transition
$F->Check_For_NextState();

#Force us to go to state 3
$BogusTest=0;
#Drive the state machine thru one transition
$F->Check_For_NextState();

print "\nReseting:\n";
$F->State(0);
print "I will force us to fail to go to a new state:\n";
$BogusTest=0;
$F->Check_For_NextState();
