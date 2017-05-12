package NewColl;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name);
%AUTODB=
  (collection=>'NewColl',
   keys=>qq(id integer, name string));  
Class::AutoClass::declare;

1;
