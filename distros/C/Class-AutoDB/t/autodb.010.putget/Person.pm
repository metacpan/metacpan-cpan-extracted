package Person;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name sex friends hobbies);
%DEFAULTS=(friends=>[],hobbies=>[]);
%AUTODB=
  (collections=>
   {Person=>qq(id integer, name string, sex string, friends list(object)),
    HasName=>qq(id integer, name string)});
Class::AutoClass::declare;

1;
