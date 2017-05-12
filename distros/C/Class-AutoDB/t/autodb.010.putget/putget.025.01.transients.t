########################################
# retrieve objects with transients stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Transients;

my $get_type=@ARGV? shift @ARGV: 'get';
my $autodb=new Class::AutoDB(database=>testdb); # open database

# make some objects. sex & transients set in _init_self. 
# DON'T change number of objects. tests depend on having 1 object per id%3
my @objects=map {new Transients(name=>"transients $_",id=>id_next())} (0..2);
# hash keyed by id_mod3 for single object tests
my %objects=map {$_->id_mod3,$_} @objects;

# %test_args, exported by putgetUtil, sets class2colls, class2transients, coll2keys, label
my $test=new autodbTestObject(%test_args,get_type=>$get_type);
$test->test_get(labelprefix=>"$get_type Transients all:",
		get_args=>{collection=>'Transients'},
		correct_objects=>\@objects,);

$test->test_get(labelprefix=>"$get_type Transients id_mod3=0:",
		get_args=>{collection=>'Transients',id_mod3=>0},
		correct_objects=>$objects{0},);
$test->test_get(labelprefix=>"$get_type Transients id_mod3=1:",
		get_args=>{collection=>'Transients',id_mod3=>1},
		correct_objects=>$objects{1},);
$test->test_get(labelprefix=>"$get_type Transients id_mod3=2:",
		get_args=>{collection=>'Transients',id_mod3=>2},
		correct_objects=>$objects{2},);

$test->test_get(labelprefix=>"$get_type Transients list=0:",
		get_args=>{collection=>'Transients',list=>0},
		correct_objects=>[@objects{0,2}],);
$test->test_get(labelprefix=>"$get_type Transients list=1:",
		get_args=>{collection=>'Transients',list=>1},
		correct_objects=>[@objects{1,0}],);
$test->test_get(labelprefix=>"$get_type Transients list=2:",
		get_args=>{collection=>'Transients',list=>2},
		correct_objects=>[@objects{2,1}],);

done_testing();

