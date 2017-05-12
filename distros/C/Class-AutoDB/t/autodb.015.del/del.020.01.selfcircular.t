########################################
# delete selfcircular objects stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use SelfCircular;

my $del_type=@ARGV? shift @ARGV: 'del';
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @objects=$autodb->get(collection=>'SelfCircular');
report_fail
  (scalar(@objects)==2,'objects exist - probably have to rerun put script',__FILE__,__LINE__);

# del and test
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_del(labelprefix=>"$del_type all objects",del_type=>$del_type,objects=>\@objects,
		correct_diffs=>{SelfCircular=>1,SelfCircular_self_array=>2});

done_testing();

