########################################
# retrieve objects stored by 010.00 using get & find with no args. also tests count
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Person; use Student; use Place; use School; use Thing;

my $get_type=@ARGV? shift @ARGV: 'get';

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make some hobbies
my $rowing=new Thing(desc=>'rowing',id=>id_next());
my $cooking=new Thing(desc=>'cooking',id=>id_next());
my $chess=new Thing(desc=>'chess',id=>id_next());
my $go=new Thing(desc=>'go',id=>id_next());

# make some Persons, then set up friends lists.
my $joe=new Person(name=>'Joe',sex=>'M',hobbies=>[$rowing,$cooking],id=>id_next());
my $mary=new Person(name=>'Mary',sex=>'F',hobbies=>[$cooking,$chess],id=>id_next());
my $bill=new Person(name=>'Bill',sex=>'M',hobbies=>[$chess,$go],id=>id_next());
$joe->friends([$mary,$bill]);
$mary->friends([$joe,$bill]);
$bill->friends([$joe,$mary]);

# make some Places
my $isb=new Place(name=>'ISB',address=>'Seattle',id=>id_next());
my $ebi=new Place(name=>'EBI',address=>'Hinxton',country=>'UK',id=>id_next());

# make some schools
my $mit=new School
  (name=>'MIT',address=>'Cambridge',subjects=>[qw(Science Engineering)],id=>id_next());
my $ucl=new School
  (name=>'UCL',address=>'London',country=>'UK',subjects=>[qw(Law Humanities)],id=>id_next());

# make some students, then set up friends lists.
my $jane=new Student(name=>'Jane',sex=>'F',school=>$mit,id=>id_next());
my $mike=new Student(name=>'Mike',sex=>'M',school=>$mit,id=>id_next());
my $barb=new Student(name=>'Barb',sex=>'F',school=>$ucl,id=>id_next());
$jane->friends([$mary,$bill]);
$mike->friends([$joe,$bill]);
$barb->friends([$joe,$mary]);

# %test_args, exported by putgetUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);
my @objects=($rowing,$cooking,$chess,$go,$joe,$mary,$bill,$isb,$ebi,$mit,$ucl,$jane,$mike,$barb);
$test->test_get(labelprefix=>"$get_type with no arguments",get_type=>$get_type,get_args=>{},
		correct_objects=>\@objects);

done_testing();
