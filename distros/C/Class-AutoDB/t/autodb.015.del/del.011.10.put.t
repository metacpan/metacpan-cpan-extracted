########################################
# this series tests deletion of objects before they were put
# this script creates the objects, puts some, deletes some, and puts rest
# a little different from 010.00.put: hobbies rearranged. fewer persons, 1 school
########################################
use t::lib;
use strict;
use Carp;
use List::Util qw(sum);
use Test::More;
use Test::Deep;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

my $put_type=@ARGV? shift @ARGV: 'put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
my($num_things,$num_persons,$num_students,$num_friends,$num_places,$num_schools);
sub num_objects {sum($num_things,$num_persons,$num_places)}
sub num_hasname {sum($num_persons,$num_places)}
sub correct_diffs {
  norm_counts(_AutoDB=>num_objects,
	      Person=>$num_persons,
	      Student=>$num_students,
	      Place=>$num_places,
	      HasName=>num_hasname,
	     );
}

# make some hobbies
my $rowing=new Thing(desc=>'rowing',id=>id_next());
my $go=new Thing(desc=>'go',id=>id_next());
$num_things=2-1;		# subtract 1 because rowing deleted below

# make some schools
my $mit=new School
  (name=>'MIT',address=>'Cambridge',subjects=>[qw(Science Engineering)],id=>id_next());
$num_places+=$num_schools=1-1;	# subtract 1 because mit deleted below

# make some students, all have same school
my $jane=new Student(name=>'Jane',sex=>'F',school=>$mit,hobbies=>[$rowing,$go],id=>id_next());
my $mike=new Student(name=>'Mike',sex=>'M',school=>$mit,hobbies=>[$rowing,$go],id=>id_next());
my $barb=new Student(name=>'Barb',sex=>'F',school=>$mit,hobbies=>[$rowing,$go],id=>id_next());
$num_persons+=$num_students=3;

$test->old_counts;		# remember table counts before update
$autodb->put($jane);
# delete mit and rowing, then put remaining objects
$autodb->del($mit,$rowing);
$autodb->put($go,$mike,$barb);
remember_oids;
my $actual_diffs=$test->diff_counts;
my $correct_diffs=correct_diffs;
cmp_deeply($actual_diffs,$correct_diffs,'table counts');

done_testing();
