use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

# 'get' test for transients.
use PctAUTODB_Trans;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

for my $class (qw(PctAUTODB_Trans_String PctAUTODB_Trans_Array
		 PctAUTODB_Trans_unset PctAUTODB_Trans_1)) {
  my @objects=$autodb->get(collection=>'Person',name=>$class);
  is(scalar(@objects),1,"$class got one object");
  my $object=$objects[0];
  is($object->name,$class,"$class has correct name");
  is($object->id,id_next(),"$class has correct id");
  is(grep({$object->$_} qw(name id sex)),3,"$class permanents set in retrieved object");
  is(grep({$object->$_} qw(name_prefix sex_word)),0,"$class transients not set in retrieved object");
}

done_testing();

