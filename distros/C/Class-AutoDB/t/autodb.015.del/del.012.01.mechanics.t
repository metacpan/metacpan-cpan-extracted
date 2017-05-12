########################################
# delete objects for mechanics test stored by previous test
# this script just tests one value of num_objects, list_count, del_type
#   driver MUST invoke with range of parameters for test to be comprehensive
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Mechanics;

my($num_objects,$list_count,$del_type)=@ARGV;
defined $num_objects or $num_objects=1;
defined $list_count or $list_count=1;
defined $del_type or $del_type='del';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @objects=$autodb->get(collection=>'Mechanics');
report_fail
  (scalar(@objects),'objects exist - probably have to rerun put script',__FILE__,__LINE__);
report_fail
  (scalar(@objects)==$num_objects,
   'number of objects - looks like put & del scripts used different params ',__FILE__,__LINE__);

# del and test
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_del(labelprefix=>"$del_type all objects",del_type=>$del_type,
		objects=>\@objects,correct_diffs=>Mechanics->correct_diffs($list_count));

done_testing();
