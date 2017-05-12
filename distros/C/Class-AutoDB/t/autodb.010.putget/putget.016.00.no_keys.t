########################################
# simple test of collections with no keys, and classes with no collections
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use NoKeys; use NoColls;

my($num_objects,$put_type)=@ARGV;
defined $num_objects or $num_objects=3;
defined $put_type or $put_type='put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make the objects
my @objects=
  map {new NoKeys(name=>"no_keys $num_objects object $_",id=>id_next(),
		  no_colls=>new NoColls(name=>"no_colls $num_objects object $_",id=>id_next()))}
  (0..$num_objects-1);

# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
$test->test_put(labelprefix=>"$put_type:",put_type=>$put_type,
		objects=>[@objects,map {$_->no_colls} @objects],
		correct_diffs=>1);

done_testing();
