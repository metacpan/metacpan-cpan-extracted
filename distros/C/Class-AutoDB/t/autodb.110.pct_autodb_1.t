# Regression test for %AUTODB=1

package PctAUTODB_1;
use Test::More;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=1;
eval {Class::AutoClass::declare;};
ok(!$@,'%AUTODB=1 legal as expected');

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make an object, then store in database
my $object=new PctAUTODB_1(name=>'PctAUTODB_1',sex=>'F',id=>id_next());
ok_newoid($object,"PctAUTODB_1 oid before put");
remember_oids($object);
$autodb->put($object);
ok_oldoid($object,"PctAUTODB_1 oid after put");
# # make sure she's not in Person, since we're testing %AUTODB=1
# my $oid=$autodb->oid($object);
# my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM Person WHERE oid=$oid));
# ok(!$count,'PctAUTODB_1 not in Person');

done_testing();
