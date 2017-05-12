########################################
# get & delete objects, then put them. put should be nop
# partly tested in del.010.02, but this script makes sure database unchanged
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

# now put them
$test->old_counts;		# remember table counts before update
$autodb->put(@objects);
my $actual_diffs=$test->diff_counts;
my $correct_diffs={};
cmp_deeply($actual_diffs,$correct_diffs,'put after del');

done_testing();
