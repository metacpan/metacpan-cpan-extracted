########################################
# retrieve pnp (persistent+nonpersistent) objects stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Persistent00; use NonPersistent00;

my $get_type=@ARGV? shift @ARGV: 'get';
my $autodb=new Class::AutoDB(database=>testdb); # open database
# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);

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

# test_get assumes all objects persistent, so deal with non-peristence here
my $actual_p0=get_one('p0');
my $actual_p1=get_one('p1');
cmp_deeply($actual_p0,$p0,'p0 contents');
cmp_deeply($actual_p1,$p1,'p1 contents');

my @actual_reach=reach($actual_p0,$actual_p1);
my @actual_ps=grep {'Persistent00' eq ref $_} @actual_reach;
my @actual_nps=grep {'NonPersistent00' eq ref $_} @actual_reach;
my %actual_id2p=group {$_->id} @actual_ps;
my %actual_id2np=group {$_->id} @actual_nps;

is((grep {@$_==1} values %actual_id2p),2,'persistent objects: 1 copy each');
is((grep {@$_==2} values %actual_id2np),2,'non-persistent objects: 2 copies each');

# delete the non-persistent ones and let test_get do its thing
for my $object ($p0,$p1,$actual_p0,$actual_p1) {
  delete $object->{np0};
  delete $object->{np1};
}
$test->test_get(labelprefix=>"$get_type Persistent+NonPersistent:",
		get_type=>$get_type,get_args=>{collection=>'Persistent'},
		correct_objects=>[$p0,$p1],actual_objects=>[$actual_p0,$actual_p1]);

done_testing();

sub get_one {
  my($name)=@_;
  my($actual_object)=$test->do_get({collection=>'Persistent',name=>$name},$get_type,1);
  $actual_object;
#   my(@actual_objects,$count);
#   if ($get_type eq 'get') {
#     @actual_objects=$autodb->get($get_args);
#     $count=$autodb->count($get_args);
#   } elsif ($get_type=~/^find([_-]{0,1}get){0,1}$/) {
#     my $cursor=$autodb->find($get_args);
#     @actual_objects=$cursor->get;
#     $count=$cursor->count;
#   } elsif ($get_type=~/^find[_-]{0,1}get[_-]{0,1}next$/) {
#     my $cursor=$autodb->find($get_args);
#     while (my $object=$cursor->get_next) {
#       push(@actual_objects,$object);
#     } 
#     $count=$cursor->count;
#   } else {
#     confess "invalid get_type $get_type";
#   }
#   # is($count,scalar @correct_objects,$self->label.'count');
#   unless($count==1) {
#     report_fail(0,"$get_type $name count");
#     diag('   got: '.scalar @actual_objects);
#     diag('expect: 1');
#     return undef;
#   }
#  $actual_objects[0];
}
