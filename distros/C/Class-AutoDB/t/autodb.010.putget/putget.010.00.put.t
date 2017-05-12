########################################
# create and put some objects
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Person; use Student; use Place; use School; use Thing;

my $put_type=@ARGV? shift @ARGV: 'put';

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb,create=>1); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
tie_oid('create');

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args,put_type=>$put_type);

# make some hobbies
my $rowing=new Thing(desc=>'rowing',id=>id_next());
my $cooking=new Thing(desc=>'cooking',id=>id_next());
my $chess=new Thing(desc=>'chess',id=>id_next());
my $go=new Thing(desc=>'go',id=>id_next());
$test->test_put(labelprefix=>"$put_type Thing:",objects=>[$rowing,$cooking,$chess,$go],
		correct_diffs=>1);

# make some Persons, then set up friends lists.
my $joe=new Person(name=>'Joe',sex=>'M',hobbies=>[$rowing,$cooking],id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',hobbies=>[$cooking,$chess],id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',hobbies=>[$chess,$go],id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);
# store and test them
$test->test_put(labelprefix=>"$put_type Person:",objects=>[$joe,$mary,$bill],
		correct_diffs=>{Person=>1,Person_friends=>2,HasName=>1});

# make some Places
my $isb=new Place(name=>'ISB',address=>'Seattle',id=>id_next());
my $ebi=new Place(name=>'EBI',address=>'Hinxton',country=>'UK',id=>id_next());
# store and test them
$test->test_put(labelprefix=>"$put_type Place:",objects=>[$isb,$ebi],
		correct_colls=>[qw(Place HasName)],
		correct_diffs=>{Place=>1,HasName=>1});

# make some schools
my $mit=new School
  (name=>'MIT',address=>'Cambridge',subjects=>[qw(Science Engineering)],id=>id_next());
my $ucl=new School
  (name=>'UCL',address=>'London',country=>'UK',subjects=>[qw(Law Humanities)],id=>id_next());
# store and test them
$test->test_put(labelprefix=>"$put_type School:",objects=>[$mit,$ucl],
		correct_colls=>[qw(Place HasName)],
		correct_diffs=>{Place=>1,HasName=>1});

# make some students, then set up friends lists.
my $jane=new Student(name=>'Jane',sex=>'F',school=>$mit,id=>id_next());
my $mike=new Student(name=>'Mike',sex=>'M',school=>$mit,id=>id_next());
my $barb=new Student(name=>'Barb',sex=>'F',school=>$ucl,id=>id_next());
$jane->friends([$mary,$bill]);
$mike->friends([$joe,$bill]);
$barb->friends([$joe,$mary]);

# store and test them
$test->test_put(labelprefix=>"$put_type Student:",objects=>[$jane,$mike,$barb],
		correct_colls=>[qw(Person HasName Student)],
		correct_diffs=>{Person=>1,Person_friends=>2,HasName=>1,Student=>1});

# put 'em all again

my $test=new autodbTestObject
  (class2colls=>$class2colls,coll2keys=>$coll2keys,label=>\&label,put_type=>$put_type);

$test->test_put(labelprefix=>"$put_type Thing 2nd time:",objects=>[$rowing,$cooking,$chess,$go],
		old_objects=>[$rowing,$cooking,$chess,$go]);
$test->test_put(labelprefix=>"$put_type Person 2nd time:",objects=>[$joe,$mary,$bill],
		old_objects=>[$joe,$mary,$bill]);
$test->test_put(labelprefix=>"$put_type Place 2nd time:",objects=>[$isb,$ebi],
	       	old_objects=>[$isb,$ebi]);
$test->test_put(labelprefix=>"$put_type School 2nd time:",objects=>[$mit,$ucl],
		old_objects=>[$mit,$ucl]);
$test->test_put(labelprefix=>"$put_type Student 2nd time:",objects=>[$jane,$mike,$barb],
		old_objects=>[$jane,$mike,$barb]);

done_testing();
