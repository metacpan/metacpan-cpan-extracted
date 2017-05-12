#!/usr/bin/perl -w

use strict 'vars', 'subs';
use Test::More tests => 13;
use lib 't';

# little tests for those who are OO purists, and want to be able to
# call superclass accessors

use_ok("Containers");

new Object;

is_deeply(\@Object::ISA, [ qw(Object::CT) ],
	  "Intermediate class inserted");

my $self = Person->new(name => "Yourself");

$self->enlighten;

is($self->is_enlightened, 42, "Accessors now enlightened.");

my $idea = Idea->new(content => "cheese");  #bright idea!

isa_ok($idea, "Idea", "new Idea()");
isa_ok($idea, "Idea::CT", "new Idea()");

my $time;
my $belief = Belief->new
    (content => ($time = "Time is the freight train of all truth"));

isa_ok($belief, "Belief", "new Belief()");
isa_ok($belief, "Belief::CT", "new Belief() has intermediate class");
isa_ok($belief, "Idea", "new Belief() still an Idea");

is($belief->get_content, "Belief: Idea: $time",
   "Inheritance works");
bless $belief, "Truth";
is($belief->get_content, "Truth: Idea: $time",
   "Inheritance works 2");
bless $belief, "Knowledge";
is($belief->get_content, "Knowledge: Belief: Idea: $time",
   "Caveat of diamond inheritance");

my $truth = Truth->new
    (content => ("The first stage of enlightenment is pseudonirvana,"
		 ." where the subject believes they have reached "
		 ."enlightenment - alas, they have a long path to "
		 ."tread "),
     reason => "wise people say so",  # so it must be true...
    );

is ($truth->get_reason, "TRUTH: wise people say so");

my $knowledge = Knowledge->new
    (
     content => "Perhaps the accessors aren't so enlightened",
     reason  => "Bugs found by users",
    );

is ($knowledge->get_reason, "TRUTH: Bugs found by users");


