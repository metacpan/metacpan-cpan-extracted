package PctAUTODB_unset;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id);
# %AUTODB;
Class::AutoClass::declare;

1;
