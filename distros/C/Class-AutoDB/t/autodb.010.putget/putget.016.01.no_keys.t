########################################
# simple test of collections with no keys, and classes with no collections
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use NoKeys; use NoColls;

my($num_objects,$get_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make the objects
my @objects=
  map {new NoKeys(name=>"no_keys $num_objects object $_",id=>id_next(),
		  no_colls=>new NoColls(name=>"no_colls $num_objects object $_",id=>id_next()))}
  (0..$num_objects-1);

# get and test
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$get_type:",get_type=>$get_type);
$test->test_get(labelprefix=>"$get_type:",
		get_args=>{collection=>'NoKeys'},correct_objects=>\@objects);

done_testing();
