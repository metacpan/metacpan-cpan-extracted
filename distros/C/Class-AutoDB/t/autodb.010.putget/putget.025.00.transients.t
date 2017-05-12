########################################
# create and put some objects with transients
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Transients;

my $put_type=@ARGV? shift @ARGV: 'put';
# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make some objects. sex & transients set in _init_self
my @objects=map {new Transients(name=>"transients $_",id=>id_next())} (0..2);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type Transients:",objects=>\@objects,
		correct_diffs=>{Transients=>1});

# do it again
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type Transients 2nd time:",objects=>\@objects,
		old_objects=>\@objects,);

done_testing();

