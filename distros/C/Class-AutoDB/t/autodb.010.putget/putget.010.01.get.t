########################################
# retrieve objects stored by previous test
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use putgetUtil; use Person; use Student; use Place; use School; use Thing;

my($emit_count,$first_case,$get_type)=(undef,1,'get');
if (@ARGV==1 && $ARGV[0] eq 'count') {
  $emit_count=1;
} else {
  $first_case=shift @ARGV if @ARGV;
  $get_type=shift @ARGV if @ARGV;
}
my $autodb=new Class::AutoDB(database=>testdb); # open database

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
my @tests=
  (new autodbTestObject
   (%test_args,labelprefix=>"$get_type Person:",
    get_type=>$get_type,get_args=>{collection=>'Person'},
    correct_objects=>[$joe,$mary,$bill,$jane,$mike,$barb]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type Student:",
    get_type=>$get_type,get_args=>{collection=>'Student'},
    correct_objects=>[$jane,$mike,$barb]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type Place:",
    get_type=>$get_type,get_args=>{collection=>'Place'},
    correct_objects=>[$isb,$ebi,$mit,$ucl]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type males:",
    get_type=>$get_type,get_args=>{collection=>'Person',sex=>'M'},
    correct_objects=>[$joe,$bill,$mike]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type females:",
    get_type=>$get_type,get_args=>{collection=>'Person',sex=>'F'},
    correct_objects=>[$mary,$jane,$barb]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type USA Places:",
    get_type=>$get_type,get_args=>{collection=>'Place',country=>'USA'},
    correct_objects=>[$isb,$mit]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type UK Places:",
    get_type=>$get_type,get_args=>{collection=>'Place',country=>'UK'},
    correct_objects=>[$ebi,$ucl]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type Joe via Person:",
    get_type=>$get_type,get_args=>{collection=>'Person',name=>'Joe'},
    correct_objects=>[$joe]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type Mary via HasName:",
    get_type=>$get_type,get_args=>{collection=>'HasName',name=>'Mary'},
    correct_objects=>[$mary]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type Jane via Student:",
    get_type=>$get_type,get_args=>{collection=>'Student',name=>'Jane'},
    correct_objects=>[$jane]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type Mike via Person:",
    get_type=>$get_type,get_args=>{collection=>'Person',name=>'Mike'},
    correct_objects=>[$mike]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type MIT via Place:",
    get_type=>$get_type,get_args=>{collection=>'Place',name=>'MIT'},
    correct_objects=>[$mit]),
   new autodbTestObject
   (%test_args,labelprefix=>"$get_type UCL via HasName:",
    get_type=>$get_type,get_args=>{collection=>'HasName',name=>'UCL'},
    correct_objects=>[$ucl]),
   sub {
     my($real_joe)=$autodb->get(collection=>'HasName',name=>'Joe');
     new autodbTestObject
       (%test_args,labelprefix=>"$get_type Joe befriender:",
	get_type=>$get_type,get_args=>{collection=>'Person',friends=>$real_joe},
	correct_objects=>[$mary,$bill,$mike,$barb]);},
   sub {
     my($real_jane)=$autodb->get(collection=>'HasName',name=>'Jane');
     new autodbTestObject
       (%test_args,labelprefix=>"$get_type Jane befriender:",
	get_type=>$get_type,get_args=>{collection=>'Person',friends=>$real_jane},
	correct_objects=>[]);},
   sub {
     my($real_mit)=$autodb->get(collection=>'HasName',name=>'MIT');
     new autodbTestObject
       (%test_args,labelprefix=>"$get_type MIT students:",
	get_type=>$get_type,get_args=>{collection=>'Student',school=>$real_mit},
	correct_objects=>[$jane,$mike]);},
   sub {
     my($real_ucl)=$autodb->get(collection=>'Place',name=>'UCL');
     new autodbTestObject
       (%test_args,labelprefix=>"$get_type UCL students:",
	get_type=>$get_type,get_args=>{collection=>'Student',school=>$real_ucl},
	correct_objects=>[$barb]);},
  );
print(scalar @tests,"\n") and exit() if $emit_count;

# diag "\$first_case=$first_case, \$get_type=$get_type";
confess "first_case=$first_case too big. max is ".scalar @tests if $first_case>@tests;
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
# run all tests starting at $first_case. skip 0, since that's used for 'put' test
for (my $i=0; $i<@tests; $i++) {
  my $case=($first_case+$i)%@tests; 
  my $test=$tests[$case];
  $test=&$test() if 'CODE' eq ref $test;
  $test->test_get();
}

done_testing();
