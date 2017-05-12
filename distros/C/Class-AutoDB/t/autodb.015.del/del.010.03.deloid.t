########################################
# get & delete object, then access via Oid stored in another object
# objects created and stored by del.010.00.put
########################################
use t::lib;
use strict;
use Carp;
use Test::More;
use autodbTestObject;

use Class::AutoDB;
use delUtil; use Person; use Student; use Place; use School; use Thing;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
my $count=$autodb->count(collection=>'Person',name=>'Bill');
report_fail($count,'objects exist - probably have to rerun put script',__FILE__,__LINE__);

# create test object
# %test_args, exported by delUtil, sets class2colls, coll2keys, label
my $test=new autodbTestObject(%test_args);

# get & delete one object - Bill
my($bill)=$autodb->get(collection=>'Person',name=>'Bill');
$test->test_del(labelprefix=>'del Bill',object=>$bill);
# get Mary. friends are Joe, Bill. 
my($mary)=$autodb->get(collection=>'Person',name=>'Mary');
my @mary_friends=@{$mary->friends};
# check object cache before accessing friends
ok_objcache($mary_friends[0],'Oid','Person',
	    "Mary's 1st friend is Oid",__FILE__,__LINE__);
ok_objcache($mary_friends[1],'OidDeleted','Person',
	    "Mary's 2nd friend is OidDeleted",__FILE__,__LINE__);
# get Joe. friends are Mary, Bill
my($joe)=$autodb->get(collection=>'Person',name=>'Joe');
my @joe_friends=@{$joe->friends};
ok_objcache($joe_friends[0],'obj','Person',
	    "Joe's 1st friend is Person",__FILE__,__LINE__);
ok_objcache($joe_friends[1],'OidDeleted','Person',
	    "Joe's 2nd friend is OidDeleted",__FILE__,__LINE__);
# check objects
is($mary_friends[0],$joe,"Mary's 1st friend is Joe");
is($mary_friends[1],$bill,"Mary's 2nd friend is Bill");
is($joe_friends[0],$mary,"Joe's 1st friend is Mary");
is($joe_friends[1],$bill,"Joe's 2nd friend is Bill");

# access ojects. Bill should confess. Mary, Joe should work.
my $ok=1;
my $actual=eval {$bill->name;};
if ($@) {
  $ok&&=report_fail
    (scalar $@=~/Trying to access deleted object of class \S+ via method name/,
     "\$bill->name confessed but with wrong message: $@",__FILE__,__LINE__);
} else {
  $ok&&=report_fail
    (0,"\$bill->name was supposed to confess but did not",__FILE__,__LINE__);
  $ok&&=ok_objcache
    ($bill,'OidDeleted','Person',
     '\$bill->name did not fetch object',__FILE__,__LINE__,'no_report_pass');
  report_pass($ok,'Bill');
}
my $ok=1;
my $actual=eval {$mary->name;};
$ok&&=report_fail
    (!$@,"\$mary->name was not supposed to confess but did with message: $@",
     __FILE__,__LINE__);
$ok&&=report_fail
  ($actual eq 'Mary',
   "name method returned correct value. Expected 'Mary'. Got $actual",__FILE__,__LINE__);
report_pass($ok,'Mary');
my $ok=1;
my $actual=eval {$joe->name;};
$ok&&=report_fail
    (!$@,"\$joe->name was not supposed to confess but did with message: $@",
     __FILE__,__LINE__);
$ok&&=report_fail
  ($actual eq 'Joe',
   "name method returned correct value. Expected 'Joe'. Got $actual",__FILE__,__LINE__);
report_pass($ok,'Joe');

my $ok=1;
$ok&&=ok_objcache($bill,'OidDeleted','Person','Bill at end',__FILE__,__LINE__,'no_report_pass');
$ok&&=ok_objcache($mary,'obj','Person','Mary at end',__FILE__,__LINE__,'no_report_pass');
$ok&&=ok_objcache($joe,'obj','Person','Joe at end',__FILE__,__LINE__,'no_report_pass');
report_pass($ok,'object cache at end');

done_testing();
