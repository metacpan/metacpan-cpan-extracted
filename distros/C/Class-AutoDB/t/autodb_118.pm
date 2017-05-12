# Regression test: put values of wrong type
package Test;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id iwrong iwrong_list swrong swrong_list fwrong fwrong_list 
		    owrong owrong_list);
%AUTODB=(collection=>'Test', 
	 keys=>qq(id integer, name string, 
                  iwrong integer, iwrong_list list(integer),
                  swrong string, swrong_list list(string),
                  fwrong float, fwrong_list list(float),
                  owrong object, owrong_list list(object),));
Class::AutoClass::declare;

package Persistent;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name id);
%AUTODB=(collection=>'HasName',keys=>qq(id integer, name string));
Class::AutoClass::declare;

package NonPersistent;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES);
@AUTO_ATTRIBUTES=qw(name id);
Class::AutoClass::declare;

1;
