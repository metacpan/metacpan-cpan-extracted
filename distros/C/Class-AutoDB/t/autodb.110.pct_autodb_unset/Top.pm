package Top;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id);
%AUTODB=
  (collection=>'Person',
   keys=>qq(name string, id integer));  
Class::AutoClass::declare;

1;
