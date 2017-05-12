########################################
# this series tests deletion of objects before they were put
# this script gets object containing OidDeleteds
# objects created and stored by del.011.10.put
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

my($mike)=$autodb->get(collection=>'Person',name=>'Mike');
report_fail
  (ref $mike,'objects exist - probably have to rerun put script',__FILE__,__LINE__);
# test contained objects before fetch
my $mit=$mike->school;		# mit should be Oid
ok_objcache($mit,'OidDeleted','School','school starts as OidDeleted',__FILE__,__LINE__);
my @hobbies=@{$mike->hobbies};
ok_objcache($hobbies[0],'OidDeleted','Thing',
	    '1st hobby starts as OidDeleted', __FILE__,__LINE__);
ok_objcache($hobbies[1],'Oid','Thing',
	    '2nd hobby starts as OidDeleted', __FILE__,__LINE__);
# fetch, then retest contained objects
my $ok=1;
my $mit_name=eval {$mit->name;};
if ($@) {
  $ok&&=report_fail
    (scalar $@=~/Trying to access deleted object of class \S+ via method name/,
     "\$mit->name confessed but with wrong message: $@",__FILE__,__LINE__);
  $ok&&=ok_objcache
    ($mit,'OidDeleted','School',
     '\$mit->name did not fetch object',__FILE__,__LINE__,'no_report_pass');
  report_pass($ok,'school fetched as OidDeleted');
} else {
  $ok&&=report_fail
    (0,"\$mit->name was supposed to confess but did not",__FILE__,__LINE__);
}
my $ok=1;
my $rowing_desc=eval {$hobbies[0]->desc;};
if ($@) {
  $ok&&=report_fail
    (scalar $@=~/Trying to access deleted object of class \S+ via method desc/,
     "\$rowing->desc confessed but with wrong message: $@",__FILE__,__LINE__);
  $ok&&=ok_objcache
    ($hobbies[0],'OidDeleted','Thing',
     '\$rowing->desc did not fetch object',__FILE__,__LINE__,'no_report_pass');
  report_pass($ok,'1st hobby fetched as OidDeleted');
} else {
  $ok&&=report_fail
    (0,"\$rowing->desc was supposed to confess but did not",__FILE__,__LINE__);
}
my $ok=1;
my $go_desc=eval {$hobbies[1]->desc;};
$ok&&=report_fail
  (!$@,"\$go->desc was not supposed to confess but did with message: $@",
     __FILE__,__LINE__);
$ok&&=report_fail
  ($go_desc eq 'go',
   "desc method returned correct value. Expected 'go'. Got $go_desc",__FILE__,__LINE__);
$ok&&=ok_objcache
  ($hobbies[1],'object','Thing',
     '\$rowing->desc did not fetch object',__FILE__,__LINE__,'no_report_pass');
report_pass($ok,'2nd hobby fetched as object');

done_testing();
