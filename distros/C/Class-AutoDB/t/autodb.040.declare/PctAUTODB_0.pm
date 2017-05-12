# %AUTODB example from DESCRIPTION/Defining a persistent class 

package PctAUTODB_0;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=0;			# illegal
Class::AutoClass::declare;

1;
