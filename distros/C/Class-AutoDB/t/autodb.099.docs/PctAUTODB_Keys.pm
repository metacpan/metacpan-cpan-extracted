# %AUTODB example from DESCRIPTION/Defining a persistent class
# each package tests a different keys format

package PctAUTODB_Keys_String_AllTyped;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',keys=>qq(name string, sex string, id integer));  
Class::AutoClass::declare;

package PctAUTODB_Keys_String_SomeTyped;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',keys=>'name, sex, id integer');  
Class::AutoClass::declare;

package PctAUTODB_Keys_Hash_AllTyped;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',keys=>{name=>'string', sex=>'string', id=>'integer'});  
Class::AutoClass::declare;

package PctAUTODB_Keys_Hash_SomeTyped;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',keys=>{name=>'', sex=>'', id=>'integer'});  
Class::AutoClass::declare;

package PctAUTODB_Keys_Array;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'PersonStrings',keys=>[qw(name sex id)]);  
Class::AutoClass::declare;

1;
