########################################
# create and put some selfcircular objects
# does NOT check shared structure which is tested elsewhere
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use SelfCircular;

my $put_type=@ARGV? shift @ARGV: 'put';
# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make some objects. self-circularity done in _init_self
my $obj0=new SelfCircular(name=>'selfcircular 0',id=>id_next());
my $obj1=new SelfCircular(name=>'selfcircular 1',id=>id_next());

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type SelfCircular:",objects=>[$obj0,$obj1],
	       correct_diffs=>{SelfCircular=>1,SelfCircular_self_array=>2});

# do it again
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type SelfCircular 2nd time:",objects=>[$obj0,$obj1],
		old_objects=>[$obj0,$obj1]);

done_testing();
