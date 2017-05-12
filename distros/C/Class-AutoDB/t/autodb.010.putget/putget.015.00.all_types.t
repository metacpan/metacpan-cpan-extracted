########################################
# create and put some objects w/ all types of keys
# first set (00, 01) test nulls, zeros, and 1 normal value per key
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use AllTypes;

my $put_type=@ARGV? shift @ARGV: 'put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects. 
# values are (1) base undef, (2) all undef, 
#            (3) all natural zeros (undef for object), (4) all something 'normal'
my $p=new Persistent(name=>'persistent',id=>id_next());
my @objects=
    (new AllTypes(name=>'all_types base undef',id=>id_next()),
     new AllTypes(name=>'all_types all undef',id=>id_next(),
		  string_list=>[(undef)x3],integer_list=>[(undef)x3], float_list=>[(undef)x3],
		  object_list=>[(undef)x3]),
     new AllTypes(name=>'all_types natural zero',id=>id_next(),
		  string_key=>'',integer_key=>0,float_key=>0.0,object_key=>undef,
		  string_list=>[('')x3],integer_list=>[(0)x3], float_list=>[(0.0)x3],
		  object_list=>[(undef)x3]),
     new AllTypes(name=>'all_types normal',id=>id_next(),
		  string_key=>'one',integer_key=>1,float_key=>1.1,object_key=>$p,
		  string_list=>[('one')x3],integer_list=>[(1)x3], float_list=>[(1.1)x3],
		  object_list=>[($p)x3]),
    );

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);

# test the objects. do it one-by-one so correct_diffs can be set
for my $object ($p,@objects) {
  my $correct_diffs=$object->correct_diffs;
  $test->test_put(labelprefix=>"$put_type:",object=>$object,correct_diffs=>$correct_diffs);
}

done_testing();
