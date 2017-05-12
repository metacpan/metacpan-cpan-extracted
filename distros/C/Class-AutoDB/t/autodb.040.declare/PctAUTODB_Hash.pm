# %AUTODB example from DESCRIPTION/Defining a persistent class

package PctAUTODB_Hash;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=(collections=>{Person=>{name=>'string', sex=>'string', id=>'integer'},
		       HasName=>'name'});
Class::AutoClass::declare;

1;
