########################################
# get & delete objects, then get them again. 2nd get should get nothing
# objects created and stored by del.010.00.put
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
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

# diag "\$first_case=$first_case, \$put_type=$put_type";
confess "first_case=$first_case too big. max is ".scalar @objects if $first_case>@objects;
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# create test object
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);

# delete the objects
$autodb->del(@objects);

# now get them again
my @persons=$autodb->get(collection=>'Person');
my @places=$autodb->get(collection=>'Place');
my @things=map {@{$_->hobbies}} @persons; # Things have no collection. get via hobbies
my @objects=(@persons,@places,@things);
is(scalar(@objects),0,'get after del');

done_testing();
