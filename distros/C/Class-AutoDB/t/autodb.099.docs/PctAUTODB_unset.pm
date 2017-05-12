# %AUTODB example from DESCRIPTION/Defining a persistent class 

package PctAUTODB_unset;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
# %AUTODB;
Class::AutoClass::declare;

package PctAUTODB_unset_Person;
use base qw(Person);
# use vars qw(@AUTO_ATTRIBUTES %AUTODB);
# @AUTO_ATTRIBUTES=qw(name sex id friends);
# %AUTODB;
Class::AutoClass::declare;


1;
