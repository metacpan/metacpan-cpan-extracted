########################################
# test cursor reset using objects stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil;use Place;

my $autodb=new Class::AutoDB(database=>testdb); # open database

# make 10 objects - Places are as good as any
my @correct_objects=map {new Place(name=>"object $_",id=>id_next())} (0..9);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
my $correct_objects=\@correct_objects;

my $cursor=$autodb->find(collection=>'Place');
my @actual_objects=$cursor->get;
$test->test_get(labelprefix=>'get:',
		correct_objects=>$correct_objects,actual_objects=>\@actual_objects);
# first time around, should be exhausted
my @actual_objects=$cursor->get;
cmp_bag(\@actual_objects,[],'get before reset');
my @actual_objects;
while(my $object=$cursor->get_next) {push(@actual_objects,$object)}
cmp_bag(\@actual_objects,[],'getnext before reset');

# reset and do it again
$cursor->reset;
my @actual_objects=$cursor->get;
$test->test_get(labelprefix=>'get after reset:',
                correct_objects=>$correct_objects,actual_objects=>\@actual_objects);
$cursor->reset;
my @actual_objects;
while(my $object=$cursor->get_next) {push(@actual_objects,$object)}
$test->test_get(labelprefix=>'get_next after reset:',
                correct_objects=>$correct_objects,actual_objects=>\@actual_objects);

# reset and do it 2 pieces
$cursor->reset;
my @actual_objects;
for my $i (0..4) {push(@actual_objects,$cursor->get_next)}
push(@actual_objects,$cursor->get);
$test->test_get(labelprefix=>'get_next, then get after reset:',
		correct_objects=>$correct_objects,actual_objects=>\@actual_objects);

# put another object. reset should see it.
my $object=new Place(name=>"object new",id=>id_next());
$autodb->put($object);
remember_oids($object);
push(@correct_objects,$object);

# reset and do it again
$cursor->reset;
my @actual_objects=$cursor->get;
$test->test_get(labelprefix=>'get after put new object:',
                correct_objects=>$correct_objects,actual_objects=>\@actual_objects);
$cursor->reset;
my @actual_objects;
while(my $object=$cursor->get_next) {push(@actual_objects,$object)}
$test->test_get(labelprefix=>'get_next after put new object:',
                correct_objects=>$correct_objects,actual_objects=>\@actual_objects);

done_testing();
