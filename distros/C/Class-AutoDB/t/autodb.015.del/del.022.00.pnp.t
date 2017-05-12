########################################
# create and put some pnp (persistent+nonpersistent) objects
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Persistent00; use NonPersistent00;

my $put_type=@ARGV? shift @ARGV: 'put';
# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make some non persistent objects
my $np0=new NonPersistent00(name=>'np0',id=>id_next());
my $np1=new NonPersistent00(name=>'np1',id=>id_next());

# make some persistent objects
my $p0=new Persistent00(name=>'p0',id=>id_next());
my $p1=new Persistent00(name=>'p1',id=>id_next());

# link them together
$p0->fini($p0,$p1,$np0,$np1);
$p1->fini($p0,$p1,$np0,$np1);
$np0->fini($p0,$p1,$np0,$np1);
$np1->fini($p0,$p1,$np0,$np1);

# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type Persistent+NonPersistent:",objects=>[$p0,$p1],
		correct_diffs=>{Persistent=>1});

my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type Persistent+NonPersistent 2nd time:",objects=>[$p0,$p1],
		old_objects=>[$p0,$p1]);

done_testing();
