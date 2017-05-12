# %AUTODB example from DESCRIPTION/Defining a persistent class

package PctAUTODB_List_String;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=(collections=>'Person HasName');
Class::AutoClass::declare;

package PctAUTODB_List_Array;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=(collections=>[qw(Person HasName)]);
Class::AutoClass::declare;

1;
