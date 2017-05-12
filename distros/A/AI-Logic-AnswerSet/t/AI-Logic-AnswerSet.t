# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl AI-Logic-AnswerSet.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('AI::Logic::AnswerSet') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use AI::Logic::AnswerSet;
my $program = "b(X):-a(X).";
AI::Logic::AnswerSet::addCode($program,"a(1).");
