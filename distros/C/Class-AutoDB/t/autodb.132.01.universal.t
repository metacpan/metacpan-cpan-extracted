# Regression test: when invoking a UNIVERSAL method (isa, can, DOES, VERSION) on Oid or
# OidDelelted, the method was not redispatched to the real class

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

use autodb_132;

my $autodb=new Class::AutoDB(-database=>testdb);

# NG 12-11-29: only test DOES in perls > 5.10. 
# Note: $^V returns real string in perls > 5.10, and v-string in earlier perls
#   regexp below fails in earlier perls. this is okay
my($perl_main,$perl_minor)=$^V=~/^v(\d+)\.(\d+)/; # perl version
my $does_ok=($perl_main>=5 && $perl_minor>=10);

# retrieve and check one Person
my($joe)=$autodb->get(-collection=>'Person',-name=>'Joe');
ok($joe->isa('Person'),'real object: isa');
ok($joe->can('eat'),'real object: can');
ok($joe->DOES('Person'),'real object: DOES') if $does_ok;
is($joe->VERSION,$Person::VERSION,'real object: VERSION');

# do it for Oid. all should work
my $mary=$joe->friends->[0];
is(ref $mary,'Class::AutoDB::Oid','object is Oid - sanity check');
ok($mary->isa('Person'),'Oid: isa');
ok($mary->can('eat'),'Oid: can');
ok($mary->DOES('Person'),'Oid: DOES') if $does_ok;
is($mary->VERSION,$Person::VERSION,'Oid: VERSION');
is(ref $mary,'Class::AutoDB::Oid','Oid not fetched');

# do it for OidDeleted. all should confess
$autodb->del($mary);
is(ref $mary,'Class::AutoDB::OidDeleted','object is OidDeleted - sanity check');
test_del($mary,'isa',__FILE__,__LINE__);
test_del($mary,'can',__FILE__,__LINE__);
test_del($mary,'DOES',__FILE__,__LINE__) if $does_ok;
test_del($mary,'VERSION',__FILE__,__LINE__);
is(ref $mary,'Class::AutoDB::OidDeleted','OidDeleted not fetched');

ok(1,'end of test');
done_testing();

sub test_del {
  my($obj,$method,$file,$line)=@_;
  my $actual=eval {$obj->$method;};
  my $ok=1;
  my $oid=$obj->{_OID};
  my $class=$obj->{_CLASS};
  if ($@) {
    $ok&&=report_fail
      (scalar $@=~/Trying to access deleted object of class $class via method $method \(oid=$oid\)/,
       "OidDeleted: $method confessed but with wrong message: $@",$file,$line);
  } else {
    $ok&&=report_fail
      (0,"OidDeleted: $method was supposed to confess but did not",$file,$line);
  }
  report_pass($ok,"OidDeleted: $method");
}
