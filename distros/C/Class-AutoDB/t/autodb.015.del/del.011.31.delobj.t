########################################
# this series tests deletion of objects and Oids while cursor active
# OBSOLETE: superceded by series 040
# this script tests deletion of objects
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use delUtil;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

my $num_students=5;
my $num_schools=5;
my($ok,$details);

# get objects
my @students=$autodb->get(collection=>'Student');
report_fail
  (scalar @students,'objects exist - probably have to rerun put script',__FILE__,__LINE__);
report_fail
  (scalar @students==$num_students,
   'number of objects - looks like put & del scripts used different params ',__FILE__,__LINE__);
my @schools=$autodb->get(collection=>'Place');
report_fail
  (scalar @schools,'objects exist - probably have to rerun put script',__FILE__,__LINE__);
report_fail
  (scalar @schools==$num_schools,
   'number of objects - looks like put & del scripts used different params ',__FILE__,__LINE__);

# for sanity, make sure Students present in cache as objects
$ok=1;
for my $i (0..4) {
  my $student=$students[$i];
  $ok&&=ok_objcache($student,'object','Student','at start: Student in object cache as object',
		    __FILE__,__LINE__,'no_report_pass');
  last unless $ok;
}
# open cursor over Students
my $cursor=$autodb->find(collection=>'Student');
# del some students, then get via cursor
$autodb->del($students[0],$students[2],$students[4]);
my @actual=$cursor->get;
my $count=scalar @actual;
$ok=1;
$ok&&=report_fail
  ($count==$num_students-3,
   "open cursor: number of students. Expected ".($num_students-3)." Got $count",
   __FILE__,__LINE__);
if ($ok) {
  @actual=sort {$a->name cmp $b->name} @actual;
  my @correct=@students[1,3];
  ($ok,$details)=cmp_details(\@actual,bag(@correct));
  report($ok,'open cursor: correct objects',__FILE__,__LINE__,$details);
}
$ok=1;
for my $i (0,2,4) {
  my $student=$students[$i];
  $ok&&=ok_objcache($student,'OidDeleted','Student','get mangled deleted object in cache',
	    __FILE__,__LINE__,'no_report_pass');
  last unless $ok;
}
for my $i (1,3) {
  my $student=$students[$i]; 
  $ok&&=ok_objcache($student,'object','Student','get mangled non-deleted object in cache',
	    __FILE__,__LINE__,'no_report_pass');
  last unless $ok;
}
report_pass($ok,'open cursor: correct object cache after del & get');

# for sanity, make sure Schools present in cache as objects
$ok=1;
for my $i (0..4) {
  my $school=$schools[$i];
  $ok&&=ok_objcache($school,'object','School','at start: School in object cache as object',
		    __FILE__,__LINE__,'no_report_pass');
  last unless $ok;
}
# open & start cursor over Schools
$ok=1;
my $cursor=$autodb->find(collection=>'Place');
my $school=$cursor->get_next;
# del some schools, then get via cursor
$autodb->del($schools[0],$schools[2],$schools[4]);
my @actual=$cursor->get;
my $count=scalar @actual;
$ok&&=report_fail
  ($count==$num_schools-3,
   "started cursor: number of schools. Expected ".($num_schools-3)." Got $count",
   __FILE__,__LINE__);
if ($ok) {
  @actual=sort {$a->name cmp $b->name} @actual;
  my @correct=@schools[1,3];
  ($ok,$details)=cmp_details(\@actual,bag(@correct));
  report($ok,'started cursor: correct objects',__FILE__,__LINE__,$details);
}
$ok=1;
for my $i (0,2,4) {
  my $school=$schools[$i];
  $ok&&=ok_objcache($school,'OidDeleted','School','get mangled deleted object in cache',
	    __FILE__,__LINE__,'no_report_pass');
  last unless $ok;
}
for my $i (1,3) {
  my $school=$schools[$i]; 
  $ok&&=ok_objcache($school,'object','School','get mangled non-deleted object in cache',
	    __FILE__,__LINE__,'no_report_pass');
  last unless $ok;
}
report_pass($ok,'started cursor: correct object cache after del & get');

done_testing();
