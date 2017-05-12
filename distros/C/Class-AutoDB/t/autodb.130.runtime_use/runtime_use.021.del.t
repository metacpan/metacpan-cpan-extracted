# Regression test: runtime use. 020, 021 test put & del
# all classes use the same collection. 
# the 'put' test stores objects of different classes in 'top' object's list attribute
# the 'del' test gets 'top' then deletes objects from list
#   some cases should be okay; others should fail 

use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbTestObject;
use autodbUtil;
                    # do NOT use the 'RunTimeUse' classes. that's the whole point!
use CompileTimeUse; # use RunTimeUseOk; use RunTimeUseBad;

my $autodb=new Class::AutoDB(database=>testdb); # open database
my($top)=$autodb->get(collection=>'HasName',name=>'top');
my @objects=@{$top->list};
my @oids=map {$autodb->oid($_)} @objects;

# for sanity, check object cache
ok_objcache($objects[0],'Oid','CompileTimeUse','before del: CompileTimeUse object Oid');
ok_objcache($objects[1],'Oid','RunTimeUseOk','before del: RunTimeUseOk object Oid');
ok_objcache($objects[2],'Oid','RunTimeUseNotOk','before del: RunTimeUseNotOk object Oid');
# for sanity, check database
my @classes=qw(CompileTimeUse RunTimeUseOk RunTimeUseNotOk);
for(my $i=0; $i<@oids; $i++) {
  my $oid=$oids[$i];
  my $class=$classes[$i];
  my $ok=1;
  my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid));
  $ok&&=report_fail($count==1,"before del: $class object in _AutoDB table");
  my($count)=dbh->selectrow_array
    (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NOT NULL));
  $ok&&=report_fail($count==1,"before del: $class object in _AutoDB and NOT NULL");
  my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM HasName WHERE oid=$oid));
  $ok&&=report_fail($count==1,"before del: $class object in HasName table");
  report_pass($ok,"before del: $class object in _AutoDB and HasName tables");
}

# delete the objects. 1st two should work. third not
my $i=0;
my $ok=1; my $object=$objects[$i]; my $oid=$oids[$i]; my $class=$classes[$i]; $i++;
eval {$autodb->del($object);};
is($@,''," del of $class object ran");

ok_objcache($object,'OidDeleted',$class,"after del: $class object OidDeleted in cache");
my($count)=dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NULL));
$ok&&=report_fail($count==1,"after del: $class object in _AutoDB as NULL");
my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM HasName WHERE oid=$oid));
$ok&&=report_fail($count==0,"after del: $class object deleted from HasName table");
report_pass($ok,"aftet del: $class object deleted from database");

my $ok=1; my $object=$objects[$i]; my $oid=$oids[$i]; my $class=$classes[$i]; $i++;
eval {$autodb->del($object);};
is($@,''," del of $class object ran");

ok_objcache($object,'OidDeleted',$class,"after del: $class object OidDeleted in cache");
my($count)=dbh->selectrow_array
  (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NULL));
$ok&&=report_fail($count==1,"after del: $class object in _AutoDB as NULL");
my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM HasName WHERE oid=$oid));
$ok&&=report_fail($count==0,"after del: $class object deleted from HasName table");
report_pass($ok,"aftet del: $class object deleted from database");

my $ok=1; my $object=$objects[$i]; my $oid=$oids[$i]; my $class=$classes[$i]; $i++;
eval {$autodb->del($object);};
like($@,qr/Can't locate RunTimeUseNotOk/," del of $class object failed as expected");

ok_objcache($object,'Oid',$class,"after failed del: $class object Oid in cache");
my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid));
$ok&&=report_fail($count==1,"after failed del: $class object in _AutoDB table");
my($count)=dbh->selectrow_array
    (qq(SELECT COUNT(oid) FROM _AutoDB WHERE oid=$oid AND object IS NOT NULL));
$ok&&=report_fail($count==1,"after failed del: $class object in _AutoDB and NOT NULL");
my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM HasName WHERE oid=$oid));
$ok&&=report_fail($count==1,"after failed del: $class object in HasName table");
report_pass($ok,"after failed del: $class object in _AutoDB and HasName tables");

done_testing();

