########################################
# delete objects stored by previous test for testing shared and non-shared structure
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use List::MoreUtils qw(uniq);
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Structure;

my $del_type=@ARGV? shift @ARGV: 'del';
my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @objects=$autodb->get(collection=>'Structure');
report_fail
  (scalar(@objects)==2,'objects exist - probably have to rerun put script',__FILE__,__LINE__);

# del and test
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_del(labelprefix=>"$del_type all objects",del_type=>$del_type,objects=>\@objects);

done_testing();
