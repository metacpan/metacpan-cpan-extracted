# %AUTODB examples from DESCRIPTION/Defining a persistent class

package PctAUTODB_Trans_Base;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends name_prefix sex_word);
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 $self->name_prefix($self->name.' prefix');
 $self->sex_word($self->sex eq 'M'? 'male': 'female');
}

package PctAUTODB_Trans_String;
use base qw(PctAUTODB_Trans_Base);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
# @AUTO_ATTRIBUTES=qw(name sex id friends name_prefix sex_word);
%AUTODB=(collection=>'Person', 
	 keys=>qq(name string, sex string, id integer),
	 transients=>qq(name_prefix sex_word));
Class::AutoClass::declare;

package PctAUTODB_Trans_Array;
use base qw(PctAUTODB_Trans_Base);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
# @AUTO_ATTRIBUTES=qw(name sex id friends name_prefix sex_word);
%AUTODB=(collections=>{Person=>qq(name string, sex string, id integer),
		       HasName=>'name'},
	 transients=>[qw(name_prefix sex_word)]);
Class::AutoClass::declare;

package PctAUTODB_Trans_BaseP;
use base qw(PctAUTODB_Trans_Base);
use vars qw(%AUTODB);
%AUTODB=(collection=>'Person', 
	 keys=>qq(name string, sex string, id integer),
	 transients=>qq(name_prefix sex_word));
Class::AutoClass::declare;

package PctAUTODB_Trans_unset;
use base qw(PctAUTODB_Trans_BaseP);
Class::AutoClass::declare;

package PctAUTODB_Trans_1;
use base qw(PctAUTODB_Trans_BaseP);
use vars qw(%AUTODB);
%AUTODB=1;
Class::AutoClass::declare;

1;
