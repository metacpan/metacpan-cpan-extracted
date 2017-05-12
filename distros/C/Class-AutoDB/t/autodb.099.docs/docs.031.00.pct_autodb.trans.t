use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

# 'put' test for transients.
use PctAUTODB_Trans;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');

for my $class (qw(PctAUTODB_Trans_String PctAUTODB_Trans_Array
		 PctAUTODB_Trans_unset PctAUTODB_Trans_1)) {
  my $object=test_single($class);
  is(grep({$object->$_} qw(name id sex)),3,"$class permanents set in new object");
  is(grep({$object->$_} qw(name_prefix sex_word)),2,"$class transients set in new object");
}

done_testing();

