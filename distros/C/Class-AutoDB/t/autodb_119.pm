package Person;
use Class::AutoClass;
@ISA=qw(Class::AutoClass);
  
@AUTO_ATTRIBUTES=qw(name sex friends);
%AUTODB=
  (-collection=>'Person',
   -keys=>qq(name string, sex string, friends list(object)));
Class::AutoClass::declare;

1;
