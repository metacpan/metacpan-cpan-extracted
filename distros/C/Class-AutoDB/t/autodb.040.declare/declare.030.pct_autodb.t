use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

# NG 11-01-07: added create=>1. longstanding bug
# my $autodb=new Class::AutoDB(database=>testdb); # open database
my $autodb=new Class::AutoDB(database=>testdb,create=>1); # create database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

# %AUTODB unset. no base classes. therefore non-persistent
use PctAUTODB_unset;
my $object=new PctAUTODB_unset(name=>'PctAUTODB_unset',sex=>'F',id=>id_next());
my $oid=$autodb->oid($object);	# nonperistent objects don't have oids
is($oid,undef,'PctAUTODB_unset oid');
eval {$autodb->put($object)};	# illegal - nonperistent objects can't be put
ok($@,'PctAUTODB_unset put');
my $count0=count_autodb();	# number of AutoDB objects before put_objects
$autodb->put_objects;		# shouldn't put anything
my $count1=count_autodb();	# number of AutoDB objects after put_objects
is($count1,$count0,'PctAUTODB_unset put_objects');

# %AUTODB unset. persistent base class
test_single('PctAUTODB_unset_Person');

# %AUTODB=0. illegal
eval {require PctAUTODB_0;}; 
ok($@,'PctAUTODB_0');

# %AUTODB=1
use PctAUTODB_1;
my $object=new PctAUTODB_1(name=>'PctAUTODB_1',sex=>'F',id=>id_next());
ok_newoid($object,"PctAUTODB_1 oid before put");
$autodb->put($object);
remember_oids($object);
ok_oldoid($object,"PctAUTODB_1 oid after put");
# make sure she's not in Person, since we're testing %AUTODB=1
my $oid=$autodb->oid($object);
my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM Person WHERE oid=$oid));
ok(!$count,'PctAUTODB_1 not in Person');

# %AUTODB standard single collection form
use PctAUTODB_StdSingle;
test_single('PctAUTODB_StdSingle');

# %AUTODB standard single collection form. different keys formats
use PctAUTODB_Keys;
# keys=>qq(name string, sex string, id number)
test_single('PctAUTODB_Keys_String_AllTyped');
# keys=>'name, sex, id number'
test_single('PctAUTODB_Keys_String_SomeTyped');
# keys=>{name=>'string', sex=>'string', id=>'number'}
test_single('PctAUTODB_Keys_Hash_AllTyped');
# keys=>{name=>'', sex=>'', id=>'number'}
test_single('PctAUTODB_Keys_Hash_SomeTyped');
# keys=>[qw(name sex id)]
test_single('PctAUTODB_Keys_Array',qw(PersonStrings));

# %AUTODB HASH of collections form
use PctAUTODB_Hash;
test_single('PctAUTODB_Hash',qw(Person HasName));

# %AUTODB list of collections form
use PctAUTODB_List;
# %AUTODB=(collections=>'Person HasName');
test_single('PctAUTODB_List_String',qw(Person HasName));
# %AUTODB=(collections=>[qw(Person HasName)]);
test_single('PctAUTODB_List_Array',qw(Person HasName));

# all types
use PctAUTODB_AllTypes;
my @listtables=qw(PersonAllTypes_friend_names PersonAllTypes_friend_ids 
		  PersonAllTypes_friend_ages PersonAllTypes_friends);
my $joe=new PctAUTODB_AllTypes name=>'PctAUTODB_AllTypes_Joe',id=>id_next(),age=>50.5;
my $moe=new PctAUTODB_AllTypes name=>'PctAUTODB_AllTypes_Moe',id=>id_next(),age=>60.6;
$joe->set_friends($moe);
$moe->set_friends($joe);
ok_newoids([$joe,$moe],'PctAUTODB_AllTypes oids before put','PersonAllTypes',@listtables);
$autodb->put($joe,$moe);
remember_oids($joe,$moe);

# can't use ok_oldoid on list tables, since counts not always 1
ok_oldoids([$joe,$moe],'PctAUTODB_AllTypes oids after put','PersonAllTypes');
ok_collections([$joe,$moe],'PctAUTODB_AllTypes collections after put',
	       {PersonAllTypes=>[[qw(name id age friend)],
				 [qw(friend_names friend_ids friend_ages friends)]]});

done_testing();

sub count_autodb {
  my($count)=dbh->selectrow_array(qq(SELECT COUNT(oid) FROM _AutoDB));
  $count;
}
