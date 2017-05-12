########################################
# test classes for basics pnp (persistent-nonpersistent)
########################################
package Persistent00;
use strict;
# use base qw(Class::AutoClass);
use base qw(NonPersistent00);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
# @AUTO_ATTRIBUTES=qw(id name p0 p1 np0 np1);
%AUTODB=(collection=>'Persistent',keys=>qq(id int, name string));
Class::AutoClass::declare;

1;
