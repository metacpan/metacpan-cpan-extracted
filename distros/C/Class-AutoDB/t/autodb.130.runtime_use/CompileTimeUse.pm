# Regression test: runtime use.  010, 011 test put & get. 020, 021 test put & del
# all classes use the same collection. 
# the '010.put' test stores objects of different classes in the collection 
# the 'get' test gets objects from the collection w/o first using their classes
#   some cases should be okay; others should fail 
# the '020.put' test stores objects of different classes in 'top' object's list attribute
# the 'del' test gets 'top' then deletes objects from list
# 
# this class is used at compile-time, as usual. it's used to fire off the 'get'

package CompileTimeUse;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name list);
%AUTODB=
  (collection=>'HasName',keys=>qq(id integer, name string));
Class::AutoClass::declare;

1;
