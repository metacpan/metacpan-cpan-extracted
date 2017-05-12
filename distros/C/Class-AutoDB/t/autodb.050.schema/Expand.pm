########################################
# used to test expansion of collection
########################################
package Expand;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name sex friends hobbies expand expand_list);
%DEFAULTS=(friends=>[],hobbies=>[],expand_list=>[]);
%AUTODB=
  (collections=>
   {Person=>qq(id integer, name string, sex string, friends list(object), 
               expand integer,expand_list list(int)),
    Expand=>qq(id integer, name string)});
Class::AutoClass::declare;

1;
