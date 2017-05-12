use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# make an object, then store in database
use PctAUTODB_1;
my $object=new PctAUTODB_1(name=>'PctAUTODB_1',sex=>'F',id=>id_next());
ok_newoid($object,"PctAUTODB_1 oid before put");
remember_oids($object);
$autodb->put($object);
ok_oldoid($object,"PctAUTODB_1 oid after put");
# make sure she's not in Person, since we're testing %AUTODB=1
my $oid=$autodb->oid($object);
my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM Person WHERE oid=$oid));
ok(!$count,'PctAUTODB_1 not in Person');

# make an object, then store in database
use PctAUTODB_StdSingle;
my $object=new PctAUTODB_StdSingle(name=>'PctAUTODB_StdSingle',sex=>'M',id=>id_next());
ok_newoid($object,"PctAUTODB_StdSingle oid before put");
remember_oids($object);
$autodb->put($object);
ok_oldoid($object,"PctAUTODB_StdSingle oid after put",qw(Person));
ok_collection($object,"PctAUTODB_StdSingle Person after put",'Person',[qw(name sex id)]);

done_testing();
