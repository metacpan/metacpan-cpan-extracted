package Person;
use Class::AutoClass;
@ISA=qw(Class::AutoClass);
  
@AUTO_ATTRIBUTES=qw(id name friends);
%AUTODB=(-collection=>'Person',-keys=>qq(id integer, name string));
Class::AutoClass::declare;

1;
