########################################
# test classes for basics pnp (persistent-nonpersistent)
########################################
package Persistent02;
use strict;
use base qw( NonPersistent02 Persistent00);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
# gets attributes from base classes
# @AUTO_ATTRIBUTES=qw(p_array p_hash p_array2 p_hash2 p_nonshared 
# 		    np_array np_hash np_array2 np_hash2 np_nonshared);
# %AUTODB=(collection=>'Persistent',keys=>qq(id int, name string));
Class::AutoClass::declare;

# gets fini from NonPersistent02
# sub fini {}

1;
