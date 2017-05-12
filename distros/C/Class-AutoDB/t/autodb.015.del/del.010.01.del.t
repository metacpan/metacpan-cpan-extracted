########################################
# get then delete objects stored by del.010.00.put
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

my $first_case=@ARGV? shift: 0;
my $del_type=@ARGV? shift: 'del';
my $autodb=new Class::AutoDB(database=>testdb); # open database

# get the objects
my @persons=$autodb->get(collection=>'Person');
my @places=$autodb->get(collection=>'Place');
my @things=gentle_uniq map {@{$_->hobbies}} @persons; # Things have no collection. get via hobbies
my @objects=(@persons,@places,@things);
report_fail
  (scalar(@objects),'objects exist - probably have to rerun put script',__FILE__,__LINE__);

# diag "\$first_case=$first_case, \$del_type=$del_type";
confess "first_case=$first_case too big. max is ".scalar @objects if $first_case>@objects;
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# create test object
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,del_type=>$del_type);

# now do the tests
unless ($del_type=~/multi/i) { # delete objects one-by-one starting at $first_case
  for (my $i=0; $i<@objects; $i++) {
    my $case=($first_case+$i)%@objects; 
    my $object=$objects[$case];
    my $ref=ref $object;
    my $class_label=UNIVERSAL::isa($ref,'Class::AutoDB::Oid')? "$object->{_CLASS} as $ref": $ref;
    $test->test_del
      (labelprefix=>join(' ',$del_type,'case',$case,$class_label),del_type=>$del_type,
       object=>$object);
  }
} else {			# delete objects all-at-once starting at $first_case
  $test->test_del
    (labelprefix=>"$del_type starting at case $first_case",del_type=>$del_type,
     objects=>[@objects[map {($first_case+$_)%@objects} (0..$#objects)]]);
}

done_testing();
