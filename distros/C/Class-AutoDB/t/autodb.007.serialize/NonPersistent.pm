########################################
# test classes for serialize_ok series
########################################
package NonPersistent;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES);
@AUTO_ATTRIBUTES=qw(id name p0 p1 np0 np1);
Class::AutoClass::declare;

1;
