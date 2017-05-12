########################################
# this series (10, 11) tests collections with 0-3 base & list keys
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use SomeKeys;			# NOT putgetUtil! because SomeKeys defines its own %test_args

my($get_type)=@ARGV;
my $num_objects=4*4;
defined $get_type or $get_type='get';

my $autodb=new Class::AutoDB(database=>testdb);  # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make the objects
my @classes=qw(B00L00 B01L00 B02L00 B03L00 B00L01 B01L01 B02L01 B03L01 B00L02 B01L02 B02L02 B03L02 B00L03 B01L03 B02L03 B03L03);
my @correct_objects=
  map {new $_
	 (name=>"$_",id=>id_next(),
	  base_key0=>"$_ base key0",base_key1=>"$_ base key1",base_key2=>"$_ base key2",
	  list_key0=>["$_ list key1"],list_key1=>["$_ list key1"],list_key2=>["$_ list key2"]);}
       (@classes);

# get and test
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,labelprefix=>"$get_type:",get_type=>$get_type);
my @actual_objects;
for my $class (@classes) {
  push(@actual_objects,$test->do_get({collection=>$class},$get_type,1));
}
$test->test_get(labelprefix=>"$get_type:",
		actual_objects=>\@actual_objects,correct_objects=>\@correct_objects);

done_testing();
