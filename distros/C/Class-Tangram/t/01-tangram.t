#!/usr/bin/perl -w
#
#  test script for Tangram::Object
#

use strict 'vars', 'subs';
use lib "../blib/lib";
use Test::More tests => 88;
use Data::Dumper;
use Date::Manip qw(ParseDate);

#---------------------------------------------------------------------
# Test 1:   Check Class::Tangram loads

use_ok("Class::Tangram");
use_ok("Set::Object");

#---------------------------------------------------------------------
# define our movie database
package Movie;
use vars qw(@ISA $schema);
@ISA = qw(Class::Tangram);

$schema = {
	   fields => {
		      string => [ qw(title) ],
		      int => [ qw(release_year) ],
		      # this means there is a set of 'Credit' objects
		      # related to this 'Movie' object.
		      iset =>
		      {
		       credits => 'Credit',
		      },
		     },
	  };

package Person;
use vars qw(@ISA $schema);
@ISA = qw(Class::Tangram);
$schema = {
	   fields => {
		      string => [ qw(name) ],
		      rawdatetime => [ qw(birthdate) ],
		      ref => [ qw(birth_location) ],
		      flat_hash => [ qw(flat_hash) ],
		      flat_array => [ qw(flat_array) ],
		      real => { height => undef, },
		      # This person also has a set of credits
		      iset =>
		      {
		       credits => 'Credit',
		      },
		     },
	  };

package Job;
use vars qw(@ISA $schema);
@ISA = qw(Class::Tangram);
$schema = {
	   fields => {
		      string => [ qw(job_title) ],
		      # As does this job
		      iset =>
		      {
		       credits => 'Credit',
		      },
		     }
	  };

package Credit;
use vars qw($schema);
use base qw(Class::Tangram);

my $counter;

$schema = {
	   fields => {
		      string =>
		      {
		       foo => {
			       check_func => sub {
				   die if (${$_[0]} !~ /^ba[rz]$|cheese|banana/);
				   },
			       init_default => "baz",
			       },
		       bar => {
			       init_default => sub {
				   ++$counter;
				   }
			       }
		      },
		      int =>
		      {
		       cheese => {
				  check_func => sub {
				      die "too big" if (${$_[0]} > 15);
				  },
				  init_default => 15,
				 },
		      },
		     },
	  };

package Location;
use vars qw(@ISA $schema);
@ISA = qw(Class::Tangram);
$schema = {
	   fields => {
		      string => [ qw(location) ],
		      ref => [ qw(parent_location) ],
		     }
	  };

package Testing;
use vars qw(@ISA $schema);
@ISA = qw(Class::Tangram);
# a testing class, contains lots of different types
$schema = {
	   fields => {
		      array => { test_a => { class => "Credit" } },
		      hash  => { test_h => { class => "Credit" } },
		      rawdatetime => [ qw( birth death ) ],
		      rawdate => [ qw( depart return ) ],
		      rawtime => [ qw( breakfast lunch dinner ) ],
		      dmdatetime => [ qw( attack retreat ) ],

		      string =>
		      {
		       enum_t => { sql => ("enum('bucket', 'green', "
					   ."'ambiguity')")         },
		       enum_G => { sql => ('enum("dat", "is", "wot",'
					  .'"I", "as", "erd")')     },
		       set_t  => { sql => ("set ('bucket', 'green', "
					   ."'ambiguity')")         },
		       set_G  => { sql => ('set ("dat", "is", "wot",'
					  .'"I", "as", "erd")')     },

		      },
		      transient =>
		      {
		       transient_t =>
		       {
			check_func => sub {
			    die "not a code ref"
				unless (ref ${ (shift) } eq "CODE");
			}
		       }
		      },
		      idbif =>
		      {
		       i_say_poof => # there goes another one
		       undef,
		      },
		     }
	  };

# empty subclass test
package Testing::One;
use vars qw(@ISA);
@ISA=qw(Testing);

package Testing::One::Two;
use vars qw(@ISA);
@ISA=qw(Testing::One Date::Manip);

package Testing::One::Two::Three;
use vars qw(@ISA);
@ISA=qw(Testing::One::Two);

#---------------------------------------------------------------------
# for "required" test
package Fussy;
use vars qw(@ISA $schema);
@ISA=qw(Class::Tangram);

$schema =
    {
     fields =>
     {
      string => {
		 foo => { required => 1,
			  init_default => "banana" },
		 bar => { required => "" },
		 baz => {
			 required => 1,
			 check_func => sub {
			     die "bad boy"
				 unless (${$_[0]} =~ m/cheese|^$/)
			     },
			},
		},
     }
    };

sub create {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
}


package MoreFussy;
use vars qw(@ISA);
@ISA = qw(Fussy);

#---------------------------------------------------------------------
package main;
use strict;

for my $pkg (qw(Movie Person Job Credit Location)) {
    eval { Class::Tangram::import_schema($pkg) };
    is($@, "", "import_schema('$pkg')");
}

my (@locations, @credits, @jobs, @movies, @actors);

eval {
    @locations =
        (
         new Location( location => "Grappenhall",
                       parent_location => new Location
                       ( location => "Warrington",
                         parent_location => new Location
                         ( location => "Cheshire",
                           parent_location => new Location
                           ( location => "England",
                             parent_location => new Location
                             ( location => "United Kingdom" ) ) ) ) ),
         new Location( location => "Dallas",
		       parent_location => new Location
                       ( location => "Texas",
                         parent_location => new Location
                         ( location => "United States" ) ) ),
	);

    @credits = ( map { new Credit } (1..5) );

    @jobs =
	(
	 new Job( job_title => "Dr. Frank-N-Furter",
		  credits => Set::Object->new( $credits[0] ) ),
	 new Job( job_title => "Wadsworth",
		  credits => Set::Object->new( $credits[1] ) ),
	 new Job( job_title => "Prosecutor",
		  credits => Set::Object->new( $credits[2] ) ),
	 new Job( job_title => "Long John Silver",
		  credits => Set::Object->new( $credits[3] ) ),
	 new Job( job_title => "Dr. Scott",
		  credits => Set::Object->new( $credits[4] ) ),
	);

    @movies =
	(
	 new Movie( title => "Rocky Horror Picture Show",
		    release_year => 1975,
		    credits => Set::Object->new( @credits[0, 4] ) ),
	 new Movie( title => "Clue",
		    release_year => 1985,
		    credits => Set::Object->new( $credits[1] ) ),
	 new Movie( title => "The Wall: Live in Berlin",
		    release_year => 1990,
		    credits => Set::Object->new( $credits[2] ) ),
	 new Movie( title => "Muppet Treasure Island",   
		    release_year => 1996,
		    credits => Set::Object->new( $credits[3] ) ),
	);

    @actors =
	(
	 new Person( name => "Tim Curry",
		     birthdate => "1946-04-19 12:00:00",
		     birth_location => $locations[0],
		     credits =>
		     Set::Object->new( @credits[0..3] ) ),
	 new Person( name => "Marvin Lee Aday",
		     birthdate => "1947-09-27 12:00:00",
		     birth_location => $locations[1],
		     credits =>
		     Set::Object->new( $credits[4] ) ),
	 new Person(),
	);

};

is($@, "", "new of various objects");

is($locations[0]->location, "Grappenhall", "new Location");

#---------------------------------------------------------------------
#  test set

# string
eval { $actors[0]->set_name("Timothy Curry"); };
is ($@, "", "Set string to legal value");
eval { $actors[0]->set_name("Tim Curry" x 100); };
isnt ($@, "", "Set string to illegal value");

# string sub-types: tinyblob, blob, longblob
eval {
    my $test_obj = Testing->new();

    $test_obj->set_enum_t("bucket");
    $test_obj->set_enum_t("AmBiGuIty");
    $test_obj->set_enum_G("wOt");
    $test_obj->set_enum_G("erD");
    $test_obj->set_set_t("bucket,ambiguity");
    $test_obj->set_set_G("wot,dat , I, as,erd");
    $test_obj->set_i_say_poof("der goz an udda un innit");
};
is ($@, "", "Set set/enum to legal value");

my $test_obj = Testing->new();
my $allbad = 1;
eval { $test_obj->set_enum_t("wot"); }; $@ or ($allbad = 0);
eval { $test_obj->set_enum_G("bucket"); }; $@ or ($allbad = 0);
eval { $test_obj->set_set_t("bucket,cheese"); }; $@ or ($allbad = 0);
eval { $test_obj->set_set_G("blue"); }; $@ or ($allbad = 0);

ok($allbad, "Set set/enum to illegal value");

# int
eval { $movies[0]->set_release_year("-2000"); };
is ($@, "", "Set int to legal value");

eval { $movies[0]->set_release_year("2000BC"); };
isnt ($@, "", "Set int to illegal value");

# real
eval {
    $actors[0]->set_height("1.3e7");
    $actors[0]->set_height("1.3");
    $actors[0]->set_height("-12345678735");
};
is ($@, "", "Set real to legal value");

eval { $actors[0]->set_height("12345i"); };
isnt ($@, "", "Set real to illegal value");

# obj
eval {
    $actors[1]->set_birth_location($locations[int rand scalar @locations]);
    $actors[1]->set_birth_location($locations[int rand scalar @locations]);
    $actors[1]->set_birth_location($locations[int rand scalar @locations]);
};
is ($@, "", "Set ref to legal value");

eval { $actors[0]->set_birth_location("Somewhere, over the rainbow"); };
isnt ($@, "", "Set ref to illegal value");

# array
{
    my @array = $test_obj->test_a;
    my $scalar = $test_obj->test_a;

    ok((@array == 0 and ref $scalar eq "ARRAY"),
       "Class->get(array_type) for uninitialised array");
};

# rawdatetime
eval { $actors[0]->set_birthdate("yesterday"); };
isnt ($@, "", "Set rawdatetime to illegal value");

eval { $actors[0]->set_birthdate("1234-02-02 12:34:56") };
is ($@, "", "Set rawdatetime to legal value");

# time
eval { $actors[0]->set_birthdate("yesterday"); };
isnt ($@, "", "Set rawdatetime to illegal value");
eval { $actors[0]->set_birthdate("1234-02-02 12:34:56") };
is ($@, "", "Set rawdatetime to legal value");

# rawdate
eval { $test_obj->set_depart("2002-03-22"); };
is ($@, "", "Set rawdatetime to legal value");
eval { $test_obj->set_depart("2002-03-22 12:34:56"); };
isnt ($@, "", "Set rawdate to illegal value");

# rawtime
eval { $test_obj->set_breakfast("5:45") };
is ($@, "", "Set breakfast to insane time");
eval { $test_obj->set_breakfast("sparrowfart") };
isnt ($@, "", "Set breakfast to insane and illegal value");

# dmdatetime
eval { $test_obj->set_attack(ParseDate("today")) };
is ($@, "", "Set dmdatetime to valid value");

# ooh, wouldn't this be nice if it worked?
eval { $test_obj->set_attack("yestoday") };
isnt ($@, "", "Set dmdatetime to invalid value");

# empty hash
eval {
    while ( my ($k, $v) = each %{$test_obj->test_h}) {
	1;
    }
};
is ($@, "", "Interate over undef hash attribute");

# flat_hash
eval {
    while ( my ($k, $v) = each %{$actors[0]->flat_hash}) {
	die "empty hash not so empty; $k => $v";
    }
};
is ($@, "", "Interate over undef flat_hash attribute");
is_deeply( [ $actors[0]->flat_hash ], [ ],
	   "Array context get flat_hash");

# flat_array
eval {
    for (@{$actors[0]->flat_array}) {
	die "empty array not so empty; $_";
    }
};
is_deeply( [ $actors[0]->flat_array ], [ ],
	   "Array context get flat_array");
is ($@, "", "Interate over undef flat_array attribute");

#---------------------------------------------------------------------
# check init_default
is($credits[0]->foo, "baz", "init_default scalar");
is($credits[0]->bar, 1, "init_default sub");
is($credits[3]->bar, 4, "init_default sub");

$credits[0]->set_init_default(foo => "cheese");
is(Credit->new()->foo, "cheese",
   "set_init_default as instance method");
Credit->set_init_default(foo => "banana");
is(Credit->new()->foo, "banana",
   "set_init_default as Class method");


#---------------------------------------------------------------------
# check check_func
eval {
    $credits[0]->set_foo("Anything");
};
isnt($@, "", "check_func string illegal");
eval {
    $credits[0]->set_foo("bar");
};
is($@, "", "check_func string legal");

eval { $credits[0]->set_cheese(16); };
isnt($@, "", "check_func int illegal");
eval { $credits[0]->set_cheese(-1); };
is($@, "", "check_func int legal");

#---------------------------------------------------------------------
#  check clear_refs
my $movie = new Movie;
$movie->{credits} = "something illegal";
eval { $movie->clear_refs(); };
is($@, "", "clear_refs on bogus set OK");

#---------------------------------------------------------------------
# check get on invalid fields
eval { $actors[0]->set_karma("high"); };
isnt($@, "", "Set invalid field");
eval { $locations[0]->set("cheese", "high"); };
isnt($@, "", "Set invalid field");

#---------------------------------------------------------------------
# Set::Object functions
is(ref $actors[2]->{credits}, "Set::Object", "iset init_default");
my @foo = $actors[0]->credits;
is ($#foo, 3, "list context get of set");
my $foo = $actors[0]->credits;
ok($foo->isa("Set::Object"), "scalar context get of set");
ok($actors[0]->credits_includes($foo[2]), "AUTOLOAD _includes");
$actors[0]->credits_remove($foo[2]);
ok(!$actors[0]->credits_includes($foo[2]), "AUTOLOAD _remove");
$actors[0]->credits_clear;
ok(!$actors[0]->credits_includes($foo[1]), "AUTOLOAD _clear");
$actors[0]->credits_insert($foo[1]);
ok($actors[0]->credits_includes($foo[1]), "AUTOLOAD _insert");
is($actors[0]->credits_size, 1, "AUTOLOAD _size");

#---------------------------------------------------------------------
# empty subclass test
my $test = Testing::One->new();
eval { $test->attack };
is ($@, "", "Empty subclass test 1 passed");

$test = Testing::One::Two->new();
eval { $test->attack };
is ($@, "", "Empty subclass test 2 passed");

$test = Testing::One::Two::Three->new();
eval { $test->attack };
is ($@, "", "Empty subclass test 3 passed");

#---------------------------------------------------------------------
# transient types
eval { $test->set_transient_t(sub { 37 }); };
is ($@, "", "Set transient type to legal value");
is ($test->transient_t->(), 37, "Execute transient type");
eval { $test->set_transient_t("test"); };
isnt ($@, "", "Set transient type to illegal value");

#---------------------------------------------------------------------
# "required" fields
eval { new Fussy(baz => "Wednesleydale cheese", foo => "this" ) };
isnt ($@, "", "'required' - new w/missing attribute");
eval { new Fussy(baz => "Wednesleydale cheese", bar => "hi" ) };
is ($@, "", "'required' - new w/missing attribute + default");
eval { new Fussy(baz => "Wednesleydale cheese", bar => "hi", foo => "" ) };
isnt ($@, "", "'required' - new w/missing attr + default + blank");
eval { new Fussy(foo => "bar", bar => "hi", baz => "Edam cheese")};
is ($@, "", "'required' - new all non-empty");
eval { new Fussy(foo => "bar", baz => "Gloucester cheese" ) };
isnt ($@, "", "'required' - new w/empty OK field missing");
eval { new Fussy(bar => "", foo => "bar", baz => "Leicester cheese" )};
is ($@, "", "'required' - new w/empty OK field empty");
eval { new Fussy(bar => "", foo => "bar", baz => "cheesy" )};
isnt ($@, "", "'required' - new w/reqd field that fails check_func");
eval { new Fussy(bar => "", foo => "bar", baz => "" )};
isnt ($@, "", "'required' - new w/reqd field that passes check_func");

# Does a derived class behave exactly the same?
eval { new MoreFussy(baz => "Wednesleydale cheese", foo => "this" ) };
isnt ($@, "", "subclass 'required' - new w/missing attribute");
eval { new MoreFussy(baz => "Wednesleydale cheese", bar => "hi" ) };
is ($@, "", "subclass 'required' - new w/missing attribute + default");
eval { new MoreFussy(baz => "Wednesleydale cheese", bar => "hi", foo => "" ) };
isnt ($@, "", "subclass 'required' - new w/missing attr + default + blank");
eval { new MoreFussy(foo => "bar", bar => "hi", baz => "Edam cheese")};
is ($@, "", "subclass 'required' - new all non-empty");
eval { new MoreFussy(foo => "bar", baz => "Gloucester cheese" ) };
isnt ($@, "", "subclass 'required' - new w/empty OK field missing");
eval { new MoreFussy(bar => "", foo => "bar", baz => "Leicester cheese" )};
is ($@, "", "subclass 'required' - new w/empty OK field empty");
eval { new MoreFussy(bar => "", foo => "bar", baz => "cheesy" )};
isnt ($@, "", "subclass 'required' - new w/reqd field that fails check_func");
eval { new MoreFussy(bar => "", foo => "bar", baz => "" )};
isnt ($@, "", "subclass 'required' - new w/reqd field that passes check_func");

# check when loading from DB with missing field
package Tangram::Toaster;

sub toast { Fussy->new(baz => "More cheese", bar => "hi"); }
sub burn { Fussy->new() }
sub fry { Fussy->create() }
sub dodge { (shift)->(); }

package main;

# new() should only moan about 'required' attributes missing when
# constructed from packages that aren't Tangram::, or something in
# @{(ref $self).::ISA}

eval { Tangram::Toaster::toast };
is ($@, "", "'required' - full object, Tangram:: caller, CT::new");
eval { Tangram::Toaster::burn };
is ($@, "", "'required' - short object, Tangram:: caller, CT::new");
eval { Tangram::Toaster::fry };
is ($@, "", "'required' - short object, Tangram:: caller, subclass::new");

eval { Fussy->create() };
isnt ($@, "", "'required' - short object, main:: caller, subclass::new");
eval { Fussy->create(baz => "cheese", bar => "gaga") };
is ($@, "", "'required' - short object, main:: caller, subclass::new");

eval { Tangram::Toaster::dodge(sub {  Fussy->create(); }) };
isnt ($@, "", "'required' - short object, Tangram::+main:: caller, subclass::new");
eval { Tangram::Toaster::dodge ( sub {  Fussy->create(baz => "cheese", bar => "thrrppp"); }) };
is ($@, "", "'required' - full object, Tangram::+main:: caller, subclass::new");

#----------------------------------------
#  $object->new()
my $doppelgaenger = $actors[0]->new();
is($doppelgaenger->name, $actors[0]->name, "\$object->new()");
isnt($doppelgaenger, $actors[0], "\$object->new() returns a copy");

$doppelgaenger = $actors[0]->new(name => "Joe Sullivan");
isnt($doppelgaenger->name, $actors[0]->name,
   "\$object->new() can take arguments");

*Person::get_name = sub { return "John Malcovich" };
my $john = $actors[0]->new();
undef *Person::get_name;
is($john->name, "John Malcovich", "copy uses getters");

# Still to write tests for:
#   - run time type information functions
#   - checking that fields are not auto-vivified unnecessarily
#   - function overriding works as expected
