# Regression test: runtime use
# all classes use the same collection. 
# the 'put' test stores objects of different classes in the collection 
# the 'get' test gets objects from the collection w/o first using their classes
#   some cases should be okay; others should fail 
# 
# this class is used at runtime, but since the class name and file name match,
#  it should be okay

package RunTimeUseOk;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name);
%AUTODB=
  (collection=>'HasName',keys=>qq(id integer, name string));
Class::AutoClass::declare;

1;
