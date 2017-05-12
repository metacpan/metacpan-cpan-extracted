########################################
# this series (10, 11) tests collections with 0-3 base & list keys
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use SomeKeys;			# NOT delUtil! because SomeKeys defines its own %test_args

my($del_type)=@ARGV;
my $num_objects=4*4;
defined $del_type or $del_type='del';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my @classes=qw(B00L00 B01L00 B02L00 B03L00 B00L01 B01L01 B02L01 B03L01 B00L02 B01L02 B02L02 B03L02 B00L03 B01L03 B02L03 B03L03);
my @objects;
for my $class (@classes) {
  push(@objects,$autodb->get(collection=>$class));
}
report_fail
  (scalar(@objects),'objects exist - probably have to rerun put script',__FILE__,__LINE__);
report_fail
  (scalar(@objects)==$num_objects,
   'number of objects - looks like put & del scripts used different params ',__FILE__,__LINE__);

# del and test
# %test_args, exported by SomeKeys, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$del_type:",del_type=>$del_type);

$test->test_del(labelprefix=>"$del_type all objects",del_type=>$del_type,objects=>\@objects);

done_testing();
