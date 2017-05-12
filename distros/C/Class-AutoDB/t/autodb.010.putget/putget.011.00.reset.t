########################################
# create and put some objects for reset test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Place; use School;

my $put_type=@ARGV? shift @ARGV: 'put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make 10 objects - Places are as good as any
my @objects=map {new Place(name=>"object $_",id=>id_next())} (0..9);

# store and test them
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type:",objects=>\@objects,
		correct_diffs=>{Place=>1,HasName=>1});

done_testing();
