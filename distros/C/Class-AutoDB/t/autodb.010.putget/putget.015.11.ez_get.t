########################################
# retrieve objects w/ all types of keys stored by previous test
# this set (10, 11, ...) test values that are easy to query
# this one does our standard get test for sanity sake
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use putget_015_easy; use AllTypes;

my($get_type,$num_objects)=@ARGV;
defined $get_type or $get_type='get';
defined $num_objects or $num_objects=2*3*5*2; # to cover the moduli adequately
my $list_count=3;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @all_correct_objects=
  map {new AllTypes(name=>"all_types object $_",id=>id_next())} (0..$num_objects-1);
# then set base values, followed by list values
map {$all_correct_objects[$_]->init_base_mods($_,@all_correct_objects)} (0..$num_objects-1);
map {$all_correct_objects[$_]->init_lists($list_count)} (0..$num_objects-1);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,get_type=>$get_type);
$test->test_get(labelprefix=>"$get_type all objects:",
              get_args=>{collection=>'AllTypes'},correct_objects=>\@all_correct_objects);

done_testing();
