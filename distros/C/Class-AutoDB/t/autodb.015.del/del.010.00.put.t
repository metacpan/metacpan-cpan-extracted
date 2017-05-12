########################################
# create and put some objects
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

my($emit_count,$put_type)=(undef,'put');
if (@ARGV==1 && $ARGV[0] eq 'count') {
  $emit_count=1;
} else {
  $put_type=shift @ARGV if @ARGV;
}

# create AutoDB database & SDBM files
my $autodb;
unless($emit_count) {
  $autodb=new Class::AutoDB(database=>testdb,create=>1); 
  isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
  tie_oid('create');
}

# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);
my($num_things,$num_persons,$num_students,$num_friends,$num_places,$num_schools);
sub num_objects {sum($num_things,$num_persons,$num_places)}
sub num_hasname {sum($num_persons,$num_places)}
sub correct_diffs {
  {_AutoDB=>num_objects,
     Person=>$num_persons,
       Student=>$num_students,
	 Person_friends=>$num_friends,
	   Place=>$num_places,
	     HasName=>num_hasname,
	   }
}

# make some hobbies
my $rowing=new Thing(desc=>'rowing',id=>id_next());
my $cooking=new Thing(desc=>'cooking',id=>id_next());
my $chess=new Thing(desc=>'chess',id=>id_next());
my $go=new Thing(desc=>'go',id=>id_next());
$num_things=4;

# make some Persons, then set up friends lists.
my $joe=new Person(name=>'Joe',sex=>'M',hobbies=>[$rowing,$cooking],id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',hobbies=>[$cooking,$chess],id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',hobbies=>[$chess,$go],id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);
$num_persons=3;
$num_friends=$num_persons*2;

# make some Places
my $isb=new Place(name=>'ISB',address=>'Seattle',id=>id_next());
my $ebi=new Place(name=>'EBI',address=>'Hinxton',country=>'UK',id=>id_next());
$num_places=2;

# make some schools
my $mit=new School
  (name=>'MIT',address=>'Cambridge',subjects=>[qw(Science Engineering)],id=>id_next());
my $ucl=new School
  (name=>'UCL',address=>'London',country=>'UK',subjects=>[qw(Law Humanities)],id=>id_next());
$num_places+=$num_schools=2;

# make some students, then set up friends lists.
my $jane=new Student(name=>'Jane',sex=>'F',school=>$mit,id=>id_next());
my $mike=new Student(name=>'Mike',sex=>'M',school=>$mit,id=>id_next());
my $barb=new Student(name=>'Barb',sex=>'F',school=>$ucl,id=>id_next());
$jane->friends([$mary,$bill]);
$mike->friends([$joe,$bill]);
$barb->friends([$joe,$mary]);
$num_persons+=$num_students=3;
$num_friends+=$num_students*2;

print(num_objects,"\n") and exit() if $emit_count;

# put objects and check table counts for sanity
$test->old_counts;		# remember table counts before update
$autodb->put_objects;
remember_oids;
my $actual_diffs=$test->diff_counts;
my $correct_diffs=correct_diffs;
cmp_deeply($actual_diffs,$correct_diffs,'table counts - sanity check');

done_testing();
