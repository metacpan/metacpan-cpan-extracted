########################################
# this series tests deletion of objects and Oids while cursor active
# this script does the main test
# these tests vary 3 params
# 1) the items being deleted can start as objects or Oids
# 2) the active cursor can be 'open' or 'running' 
#    open means 'find' executed but no get or get_next
#    running means 'find' and 1 or more 'get_next', but cursor not exhausted
# 3) post-del, the cursor can be accessed via 'get' (ie, get all) or 'get_next'
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use Test::Deep;
use delUtil;

use Class::AutoDB;
use delUtil; use FindDel;

my($num_objects)=@ARGV;
defined $num_objects or $num_objects=5;

# create AutoDB database & SDBM files
my $autodb=new Class::AutoDB(database=>testdb); 
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# get the top object - holds all the test objects
my($top)=$autodb->get(collection=>'FindDel',testcase=>'top');
report_fail
  (defined $top,'top object exists - probably have to rerun put script',__FILE__,__LINE__);
my $case2objects=$top->case2objects;

# vary params and do tests
for my $param1 (qw(obj oid)) {
  for my $param2 (qw(open running)) {
    for my $param3 (qw(get getnext)) {
      my $case=join('_',$param1,$param2,$param3);
      my $objects=$case2objects->{$case};
      my(@objects,$entry_type);
      # process param1: get objects or use Oids
      if ($param1 eq 'obj') {	# items start as objects, so get 'em
	@objects=$autodb->get(collection=>'FindDel',testcase=>$case);
	$entry_type='object';
      } else {			# items already Oids
	@objects=@{$case2objects->{$case}};
	$entry_type='Oid';
      }
      report_fail
	(scalar @objects==$num_objects,
	 "objects for case $case exist - probably have to rerun put script",__FILE__,__LINE__);
      my $ok=1;
      for my $object (@objects) {
	$ok&&=ok_objcache($object,$entry_type,'FindDel_case',
			  "at start: objects for case $case in object cache as $entry_type",
			  __FILE__,__LINE__,'no_report_pass');
	last unless $ok;
      }
      # process param2: do 'find' and possibly 'get_next'
      my $cursor=$autodb->find(collection=>'FindDel',testcase=>$case);
      if ($param2 eq 'running') {
	my $object=$cursor->get_next;
      }
      # del some objects/Oids
      my @evens=grep {!($_%2)} (0..$num_objects-1);
      my @odds=grep {($_%2)} (0..$num_objects-1);
      $autodb->del(@objects[@evens]);
      # process param3: get objects all-at-once or in a get_next loop
      my(@actual,@correct);
      if ($param3 eq 'get') {
	@actual=$cursor->get;
      } else {
	while (defined(my $object=$cursor->get_next)) {
	  push(@actual,$object);
	}
      }
      # now, how did we do?
      my $actual_count=scalar @actual;
      my $correct_count=$num_objects-scalar @evens;
      $ok=1;
      $ok&&=report_fail
	($actual_count==$correct_count,
	 "$case: number of object. Expected $correct_count. Got $actual_count",
	 __FILE__,__LINE__);
      if ($ok) {
	@actual=sort {$a->name cmp $b->name} @actual;
	@correct=sort {$a->name cmp $b->name} @objects[@odds];
	my($ok,$details)=cmp_details(\@actual,bag(@correct));
	report($ok,"$case: correct objects",__FILE__,__LINE__,$details);
      }
      $ok=1;
      for my $i (@evens) {
	my $object=$objects[$i];
	$ok&&=ok_objcache($object,'OidDeleted','FindDel_case',
			  'get mangled deleted object in cache',__FILE__,__LINE__,
			  'no_report_pass');
	last unless $ok;
      }
      for my $i (@odds) {
	my $object=$objects[$i]; 
	$ok&&=ok_objcache($object,'object','FindDel_case',
			  'get mangled non-deleted object in cache',
			  __FILE__,__LINE__,'no_report_pass');
	last unless $ok;
      }
      report_pass($ok,"$case: correct object cache after del & get");
    }}}

done_testing();
