########################################
# retrieve pnp (persistent+nonpersistent) objects stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use List::MoreUtils qw(uniq);
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Persistent02; use NonPersistent02;

my $get_type=@ARGV? shift @ARGV: 'get';
my $autodb=new Class::AutoDB(database=>testdb); # open database
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);

# make some non persistent objects
my $np0=new NonPersistent02(name=>'np0',id=>id_next());
my $np1=new NonPersistent02(name=>'np1',id=>id_next());

# make some persistent objects
my $p0=new Persistent02(name=>'p0',id=>id_next());
my $p1=new Persistent02(name=>'p1',id=>id_next());

# link them together and connect to arrays we expect to be non-shared in retrieved objects
my $p_nonshared=[$p0,$p1];
my $np_nonshared=[$np0,$np1];
$p0->fini($p0,$p1,$np0,$np1,$p_nonshared,$np_nonshared);
$p1->fini($p0,$p1,$np0,$np1,$p_nonshared,$np_nonshared);
$np0->fini($p0,$p1,$np0,$np1,$p_nonshared,$np_nonshared);
$np1->fini($p0,$p1,$np0,$np1,$p_nonshared,$np_nonshared);

# test_get assumes all objects persistent, so deal with non-peristence here
my $actual_p0=get_one('p0');
my $actual_p1=get_one('p1');
cmp_deeply($actual_p0,$p0,'p0 contents');
cmp_deeply($actual_p1,$p1,'p1 contents');

my @actual_reach=reach($actual_p0,$actual_p1);
my @actual_ps=grep {'Persistent02' eq ref $_} @actual_reach;
my @actual_nps=grep {'NonPersistent02' eq ref $_} @actual_reach;
my %actual_id2p=group {$_->id} @actual_ps;
my %actual_id2np=group {$_->id} @actual_nps;

is((grep {@$_==1} values %actual_id2p),2,'persistent objects: 1 copy each');
is((grep {@$_==2} values %actual_id2np),2,'non-persistent objects: 2 copies each');

test_structure($actual_p0,$actual_p1);
# delete the non-persistent ones and let test_get do its thing
for my $object ($p0,$p1,$actual_p0,$actual_p1) {
  while(my($key,$value)=each %$object) {
    next unless $key=~/^np/;
    delete $object->{$key};
  }
}
$test->test_get(labelprefix=>"$get_type Persistent+NonPersistent:",
		get_type=>$get_type,get_args=>{collection=>'Persistent'},
		correct_objects=>[$p0,$p1],actual_objects=>[$actual_p0,$actual_p1]);
done_testing();

sub get_one {
  my($name)=@_;
  my($actual_object)=$test->do_get({collection=>'Persistent',name=>$name},$get_type,1);
  $actual_object;
}

sub test_structure {
  my ($obj0,$obj1)=@_;
  isnt($obj0->p_nonshared,$obj1->p_nonshared,'nonshared p_arrays');
  isnt($obj0->np_nonshared,$obj1->np_nonshared,'nonshared np_arrays');

  my @obj0_p_arrays=uniq($obj0->p_array,@{$obj0->p_array2});
  my @obj0_p_hashes=uniq($obj0->p_hash,values %{$obj0->p_hash2});
  is(scalar @obj0_p_arrays,1,$obj0->name.' shared p_arrays');
  is(scalar @obj0_p_hashes,1,$obj0->name.' shared p_hashes');
  my @obj0_np_arrays=uniq($obj0->np_array,@{$obj0->np_array2});
  my @obj0_np_hashes=uniq($obj0->np_hash,values %{$obj0->np_hash2});
  is(scalar @obj0_np_arrays,1,$obj0->name.' shared np_arrays');
  is(scalar @obj0_np_hashes,1,$obj0->name.' shared np_hashes');

  my @obj1_p_arrays=uniq($obj1->p_array,@{$obj1->p_array2});
  my @obj1_p_hashes=uniq($obj1->p_hash,values %{$obj1->p_hash2});
  is(scalar @obj1_p_arrays,1,$obj1->name.' shared p_arrays');
  is(scalar @obj1_p_hashes,1,$obj1->name.' shared p_hashes');
  my @obj1_np_arrays=uniq($obj1->np_array,@{$obj1->np_array2});
  my @obj1_np_hashes=uniq($obj1->np_hash,values %{$obj1->np_hash2});
  is(scalar @obj1_np_arrays,1,$obj1->name.' shared np_arrays');
  is(scalar @obj1_np_hashes,1,$obj1->name.' shared np_hashes');

  my($obj0_p_array)=@obj0_p_arrays;
  my($obj0_p_hash)=@obj0_p_hashes;
  my($obj0_np_array)=@obj0_np_arrays;
  my($obj0_np_hash)=@obj0_np_hashes;

  my($obj1_p_array)=@obj1_p_arrays;
  my($obj1_p_hash)=@obj1_p_hashes;
  my($obj1_np_array)=@obj1_np_arrays;
  my($obj1_np_hash)=@obj1_np_hashes;

  isnt($obj0_p_array,$obj1_p_array,'per-object shared p_arrays not shared between objects');
  isnt($obj0_p_hash,$obj1_p_hash,'per-object shared p_hashes not shared between objects');
  isnt($obj0_np_array,$obj1_np_array,'per-object shared np_arrays not shared between objects');
  isnt($obj0_np_hash,$obj1_np_hash,'per-object shared np_hashes not shared between objects');
}
