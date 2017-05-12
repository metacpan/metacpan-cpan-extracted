# Regression test: wrong regex in Class::AutoDB::Serialize::store

package PctAUTODB_Trans_String;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends name_prefix sex_word);
%AUTODB=(collection=>'Person', 
	 keys=>qq(name string, sex string, id integer),
	 transients=>qq(name_prefix sex_word));
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 $self->name_prefix($self->name.' prefix');
 $self->sex_word($self->sex eq 'M'? 'male': 'female');
}

package main;
use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

my $autodb=new Class::AutoDB(database=>testdb); # open database
isa_ok($autodb,'Class::AutoDB','class is Class::AutoDB - sanity check');
our $ID=11300;
my $object=new PctAUTODB_Trans_String name=>'PctAUTODB_Trans_String',sex=>'M',id=>$ID++;
isa_ok($object,'PctAUTODB_Trans_String','class is PctAUTODB_Trans_String - sanity check');
$autodb->put($object);

# regression test starts here
my $oid=$autodb->oid($object);
my $objstrs=dbh->selectcol_arrayref(qq(SELECT object FROM _AutoDB WHERE oid=$oid));
is(scalar(@$objstrs),1,'count is 1'); # expect 1 result, but make sure!
my $objstr=$objstrs->[0];
# test non-transients. all should be in $objstr
for my $key (qw(name id sex)) {
  my $pat=qr/\b$key\b\W*=>/;	# eg, 'name' => ...
  like($objstr,$pat,"$key found in object");
}
# test transients. none should be in $objstr
for my $key (qw(name_prefix sex_word)) {
  my $pat=qr/\b$key\b\W*=>/;	# eg, 'name' => ...
  unlike($objstr,$pat,"$key not found in object");
}

done_testing();
