########################################
# retrieve objects stored by previous test for testing shared and non-shared structure
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use List::MoreUtils qw(uniq);
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Structure;

my $get_type=@ARGV? shift @ARGV: 'get';
my $autodb=new Class::AutoDB(database=>testdb); # open database
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
my $test=new autodbTestObject(%test_args,get_type=>$get_type);

$test->test_get(labelprefix=>"$get_type Structure:",
		get_args=>{collection=>'Structure'},
		correct_objects=>[$obj0,$obj1],);
test_structure($autodb->get(collection=>'Structure'));

done_testing();

sub test_structure {
  my ($obj0,$obj1)=@_;
  isnt($obj0->nonshared,$obj1->nonshared,'nonshared arrays');

  my @obj0_arrays=uniq($obj0->self_array,@{$obj0->self_array2});
  my @obj0_hashes=uniq($obj0->self_hash,values %{$obj0->self_hash2});
  is(scalar @obj0_arrays,1,$obj0->name.' shared arrays');
  is(scalar @obj0_hashes,1,$obj0->name.' shared hashes');

  my @obj1_arrays=uniq($obj1->self_array,@{$obj1->self_array2});
  my @obj1_hashes=uniq($obj1->self_hash,values %{$obj1->self_hash2});
  is(scalar @obj1_arrays,1,$obj1->name.' shared arrays');
  is(scalar @obj1_hashes,1,$obj1->name.' shared hashes');

  my $obj0_array=$obj0_arrays[0];
  my $obj0_hash=$obj0_hashes[0];
  my $obj1_array=$obj1_arrays[0];
  my $obj1_hash=$obj1_hashes[0];

  isnt($obj0_array,$obj1_array,'shared arrays not shared between objects');
  isnt($obj0_hash,$obj1_hash,'shared hashes not shared between objects');
}
