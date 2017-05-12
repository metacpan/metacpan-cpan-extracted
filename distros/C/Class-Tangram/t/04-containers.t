#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;

BEGIN {
    ( ! -d "t" ) && (chdir "..");
}

use lib "t";

require 't/Containers.pm';

# meet Joe.
my $joe = new Person(name => "Joe Average");
my $car = new Object(description => "Red Car");

$car->set_owner($joe);

is($joe->get_posessions(0), $car, "Joe's first posession is his car");
ok($joe->posessions->includes($car), "Joe's posessions are a set");
ok($joe->posessions_includes($car), "Joe's set of posessions is encapsulated");

my $belief;
$joe->beliefs_insert
    (
     $belief =
     Belief->new(content => "Milk is good for you",
                 basises => [ Idea->new(content => "Got milk?") ]),
    );

# get contents of a container by evaluating it in list context
my @test = $joe->beliefs;
ok(@test == 1, "Basic container sanity remains");

# companion associations are symmetric entities.
# by making joe a believer, he becomes a perpetrator of the belief
ok($belief->perpetrators_includes($joe), "Companion containers work");

# so we can write lots of other code and not care about the types of
# containers being used
my $truth = Truth->new( content => "Marijuana is a good food",
			reason => ("Sole source of all essential "
				   ."proteins required for human life"
				   ." in perfect balance in the plant"
				   ." kingdom") );
$joe->hear($truth);
ok($joe->closed_to_includes($truth),
   "Joe hears an unpopular opinion");

$belief = Belief->new(content => "Drugs are bad for you",
		      basises => [ Idea->new(content => "Because they're "
					     ."bad, m'kay?") ],
		      ideator => Person->new(name => "Citizen Cain"),
		     ),

# Note; beliefs is a set, but I'm passing it as a value
my $jack = new Person(name => "Jack Christian",
		      beliefs => $belief,
		     );
# here I'm passing it as a hash
my $jill = new Person(name => "Jill Christian",
		      beliefs => { "foobar" => $belief },
		     );

$joe->hear($belief);

ok($joe->beliefs_includes($belief) &&
   !$joe->beliefs_includes($truth),
   "Joe behaves like a normal person");

#my @caught_warnings;
#$SIG{__WARN__} = sub { push @caught_warnings, shift };

# fetching items by number from an unordered collection is frowned
# upon, but OK.
@test = $joe->get_beliefs(0, 1);

ok(@test == 2 &&
   $test[0] != $test[1], "Get by index on unordered containers");

#ok(@caught_warnings, "Looking up a container without an index raised a
#warning");    # heh not yet

$joe->enlighten;
ok($joe->knowledge_includes($truth),
   "Joe can be taught");

# OK I'll can the artistic bullshit for a bit and just get on with
# testing the raw functionality :-)

# we've seen empathic containers already.

# Let's do some tree-like stuff with it:
my @i;

$i[0] = Idea->new(content => "marijuana is a persecuted plant",
		  basises => Set::Object->new
		                (
				 $i[1] = $truth,
				 $i[2] = Idea->new(content => "MJ is illegal")
				),
		  colloraries =>
		     [
		      $i[3] = Idea->new(content => "Not all laws are correct")
		     ]
		 );

ok($i[3]->basises_includes($i[0]),
   "Tree-like relationships via associations");
ok($i[1]->colloraries_includes($i[0]),
   "More tree checks, treat arrays like a set");

$i[3]->basises_push($i[3]);
ok($i[3]->basises_includes($i[3]), "push on set types");


$i[3]->colloraries_push($i[3]);
is($i[3]->basises_size, 2, "push on array types");
