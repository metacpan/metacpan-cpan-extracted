########################################
# retrieve objects w/ all types of keys stored by previous test
# first set (00, 01) test nulls, zeros, and 1 normal value per key
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use AllTypes;

my $get_type=@ARGV? shift @ARGV: 'get';

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
my($p)=$autodb->get(collection=>'Persistent');
is($p->name,'persistent','persistent object');

# make the objects. 
# values are (1) base undef, (2) all undef, 
#            (3) all natural zeros (undef for object), (4) all something 'normal'
# my $p=new Persistent(name=>'persistent',id=>id_next());
id_next();			# bump id since we're not making $p
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
my $test=new autodbTestObject(%test_args,get_type=>$get_type);

$test->test_get(labelprefix=>"$get_type all objects:",
	       get_args=>{collection=>'AllTypes'},correct_objects=>\@objects);

my @basekeys=qw(string_key integer_key float_key object_key);
my @listkeys=map {$_.'_list'} map {/^(.*)_/} @basekeys;
my @cases=map {/^\w+\s+(.*)$/} map {$_->name} @objects;
my %case2object=map {$cases[$_]=>$objects[$_]} (0..$#objects);
my %case2basevals=('base undef'=>[undef,undef,undef,undef],
		   'all undef'=>[undef,undef,undef,undef],
		   'natural zero'=>['',0,0.0,undef],
		   'normal'=>['one',1,1.1,$p]);
my %case2correct_base=('base undef'=>[@objects[0,1]],
		       'all undef'=>[@objects[0,1]],
		       'natural zero'=>[$objects[2]],
		       'normal'=>[$objects[3]]);
my %case2correct_list=('base undef'=>[$objects[1]],
		       'all undef'=>[$objects[1]],
		       'natural zero'=>[$objects[2]],
		       'normal'=>[$objects[3]]);
my %case2correct_all=('base undef'=>[$objects[1]],
		      'all undef'=>[$objects[1]],
		      'natural zero'=>[$objects[2]],
		      'normal'=>[$objects[3]]);

my %case2actual_base=map {$_=>get_basekeys($_)} @cases;
my %case2actual_list=map {$_=>get_listkeys($_)} @cases;
my %case2actual_all=map {$_=>get_allkeys($_)} @cases;

for my $case (@cases) {
  for my $key (@basekeys,@listkeys) {
    my $actual_objects=get_key($case,$key);
    my $correct_objects=correct_key($case,$key);
    note "$key $case: ".scalar @$correct_objects.' correct objects';
    $test->test_get(labelprefix=>"$get_type $key $case:",
		    actual_objects=>$actual_objects,correct_objects=>$correct_objects);
  }}
for my $case (@cases) {
  note "all basekeys $case: ".scalar @{$case2correct_base{$case}}.' correct objects';
  $test->test_get(labelprefix=>"$get_type all basekeys $case:",
 		  actual_objects=>$case2actual_base{$case},
		  correct_objects=>$case2correct_base{$case});
  note "all listkeys $case: ".scalar @{$case2correct_list{$case}}.' correct objects';
  $test->test_get(labelprefix=>"$get_type all listkeys $case:",
 		  actual_objects=>$case2actual_list{$case},
		  correct_objects=>$case2correct_list{$case});
  note "all keys $case: ".scalar @{$case2correct_all{$case}}.' correct objects';
  $test->test_get(labelprefix=>"$get_type all keys $case:",
 		  actual_objects=>$case2actual_all{$case},
		  correct_objects=>$case2correct_all{$case});
}

done_testing();

# get objects via query on all basekeys
sub get_basekeys {
  my($case)=@_;
  my $name="all_types $case";
  my $object=$case2object{$case};
  my @basevals=@{$case2basevals{$case}};
  my @query=(collection=>'AllTypes',map {$basekeys[$_]=>$basevals[$_]} (0..$#basekeys));
  my $count=$autodb->count(@query);
  my $objects=$autodb->get(@query);
  is($count,scalar @$objects,"$get_type $case basekeys: count matches objects");
  $objects;
}
# get objects via query on listkeys
sub get_listkeys {
  my($case)=@_;
  my $name="all_types $case";
  my $object=$case2object{$case};
  my @basevals=@{$case2basevals{$case}};
  my @query=(collection=>'AllTypes');
  for(my $i=0; $i<@basekeys; $i++) {
    my $key=$basekeys[$i];
    $key=~s/_key/_list/;
    push(@query,$key=>$basevals[$i]);
  }
  my $count=$autodb->count(@query);
  my $objects=$autodb->get(@query);
  is($count,scalar @$objects,"$get_type $case listkeys: count matches objects");
  $objects;
}
# get objects via query on all keys
sub get_allkeys {
  my($case)=@_;
  my $name="all_types $case";
  my $object=$case2object{$case};
  my @basevals=@{$case2basevals{$case}};
  my @query=(collection=>'AllTypes',map {$basekeys[$_]=>$basevals[$_]} (0..$#basekeys));
  for(my $i=0; $i<@basekeys; $i++) {
    my $key=$basekeys[$i];
    $key=~s/_key/_list/;
    push(@query,$key=>$basevals[$i]);
  }
  my $count=$autodb->count(@query);
  my $objects=$autodb->get(@query);
  is($count,scalar @$objects,"$get_type $case listkeys: count matches objects");
  $objects;
}
# get objects via query on single key
sub get_key {
  my($case,$key)=@_;
  my $name="all_types $case";
  my $object=$case2object{$case};
  my $value=$object->$key;
  $value=$value->[0] if 'ARRAY' eq ref $value;
  my @query=(collection=>'AllTypes',$key=>$value);
  my $count=$autodb->count(@query);
  my $objects=$autodb->get(@query);
  is($count,scalar @$objects,"$get_type $case $key=>$value: count matches objects");
  $objects;
}
sub correct_key {
  my($case,$key)=@_;
  my $name="all_types $case";
  my $object=$case2object{$case};
  my $value=$object->$key;
  my @correct;
  if ($key=~/list/) {
    $value=$value->[0] if 'ARRAY' eq ref $value;
    if (!defined $value) {
      @correct=grep {defined $_->$key && !defined $_->$key->[0]} @objects;
    } elsif ($key eq 'string_list') {
      @correct=grep {defined $_->$key && defined $_->$key->[0] && 
		       $_->$key->[0] eq "$value"} @objects;
    } else {
      @correct=grep {defined $_->$key && defined $_->$key->[0] && 
		       $_->$key->[0] == $value} @objects;
    }
  } else {
    if (!defined $value) {
      @correct=grep {!defined $_->$key} @objects;
    } elsif ($key eq 'string_key') {
      @correct=grep {defined $_->$key && $_->$key eq "$value"} @objects;
    } else {
      @correct=grep {defined $_->$key && $_->$key == $value} @objects;
    }
  }
  \@correct;
}
