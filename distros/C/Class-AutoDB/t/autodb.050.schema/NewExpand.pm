########################################
# used to test expansion of collection
########################################
package NewExpand;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id name expand expand_list);
%DEFAULTS=(expand_list=>[]);
%AUTODB=
  (collections=>
   {NewColl=>qq(id integer, name string),
    Expand=>qq(id integer, name string, expand integer, expand_list list(int))});
Class::AutoClass::declare;

1;
