package Student;
use base qw(Person);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(school);
%AUTODB=
  (collection=>'Student',
   keys=>qq(id integer, name string, school object));  
Class::AutoClass::declare;

1;
