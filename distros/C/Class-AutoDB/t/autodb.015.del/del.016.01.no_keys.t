########################################
# simple test of collections with no keys, and classes with no collections
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use NoKeys; use NoColls;

my($num_objects,$del_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $del_type or $del_type='del';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @objects=$autodb->get(collection=>'NoKeys');
report_fail
  (scalar(@objects),'objects exist - probably have to rerun put script',__FILE__,__LINE__);
report_fail
  (scalar(@objects)==$num_objects,
   'number of objects - looks like put & del scripts used different params ',__FILE__,__LINE__);

# del and test
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_del(labelprefix=>"$del_type all objects",del_type=>$del_type,objects=>\@objects);

done_testing();
