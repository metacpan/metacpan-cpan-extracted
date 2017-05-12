########################################
# retrieve objects for put mechanics test stored by previous test
# this script just tests one value of num_objects, list_count, get_type
#   driver MUST invoke with range of parameters for test to be comprehensive
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Mechanics;

my($num_objects,$list_count,$get_type)=@ARGV;
defined $num_objects or $num_objects=1;
defined $list_count or $list_count=1;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make the objects - _init_self does all the work
my @objects=
  map {new Mechanics (name=>"mechanics $num_objects+$list_count object $_",id=>id_next(),
		      num_objects=>$num_objects,list_count=>$list_count)} (0..$num_objects-1);

# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_get(labelprefix=>"$get_type:",get_type=>$get_type,
		get_args=>{collection=>'Mechanics'},correct_objects=>\@objects);

done_testing();
