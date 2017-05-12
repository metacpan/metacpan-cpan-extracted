########################################
# retrieve selfcircular objects stored by previous test
# does NOT check shared structure which is tested elsewhere
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use SelfCircular;

my $get_type=@ARGV? shift @ARGV: 'get';
my $autodb=new Class::AutoDB(database=>testdb); # open database
# make some objects. self-circularity done in _init_self
my $obj0=new SelfCircular(name=>'selfcircular 0',id=>id_next());
my $obj1=new SelfCircular(name=>'selfcircular 1',id=>id_next());

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,get_type=>$get_type);

$test->test_get(labelprefix=>"$get_type SelfCircular:",
		get_args=>{collection=>'SelfCircular'},
		correct_objects=>[$obj0,$obj1],);

done_testing();

