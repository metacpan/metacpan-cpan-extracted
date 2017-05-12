# %AUTODB example from DESCRIPTION/Persistence model. also Defining a persistent class

package PctAUTODB_1;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=1;
Class::AutoClass::declare;

1;
