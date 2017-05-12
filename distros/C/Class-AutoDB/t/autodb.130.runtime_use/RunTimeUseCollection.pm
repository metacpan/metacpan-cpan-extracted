# Regression test:  runtime use of class that changes schema
# 
# this class defines a collection and is used at runtime. 
#  the collection should be created

package RunTimeUseCollection;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name);
# %AUTODB=
#   (collection=>'RunTimeUseCollection',keys=>qq(id integer, name string));
%AUTODB=
  (collections=>{HasName=>qq(id integer, name string),
		 RunTimeUseCollection=>qq(id integer, name string)});
Class::AutoClass::declare;

1;
