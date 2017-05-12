########################################
# test classes for serialize_ok series
########################################
package Persistent;
use strict;
use base qw(Class::AutoDB::Object);

# use base qw(Class::AutoClass);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>'Serialize_OK',keys=>qq(id int, name string));

use vars qw(@AUTO_ATTRIBUTES);
@AUTO_ATTRIBUTES=qw(id name p0 p1 np0 np1);
Class::AutoClass::declare;

# these are from Serialize/testSerialize02. not sure if/why they're needed
# need a method to force fetch of embedded Oids 
# sub nop {undef;}
# use overload
#   fallback => 'TRUE';
1;
