################################################################################
# SYNOPSIS
################################################################################

# code that defines class
#
package Person;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id friends);
%AUTODB=
  (collection=>'Person',
   keys=>qq(name string, sex string, id integer));  
Class::AutoClass::declare;

1;
