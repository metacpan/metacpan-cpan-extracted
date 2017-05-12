########################################
# create and put some objects for testing shared and non-shared structure
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Structure;

my $put_type=@ARGV? shift @ARGV: 'put';
# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# make some objects. structure set up in _init_self
my $obj0=new Structure(name=>'structure 0',id=>id_next());
my $obj1=new Structure(name=>'structure 1',id=>id_next());
# connect to array we expect to be non-shared in retrieved objects
my $nonshared=[qw(nonshared array)];
$obj0->nonshared($nonshared);
$obj1->nonshared($nonshared);
# link objects together
$obj0->other($obj1);
$obj1->other($obj0);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type Structure:",objects=>[$obj0,$obj1],
		correct_diffs=>{Structure=>1});

# do it again
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
$test->test_put(labelprefix=>"$put_type Structure 2nd time:",objects=>[$obj0,$obj1],
		old_objects=>[$obj0,$obj1]);

done_testing();
