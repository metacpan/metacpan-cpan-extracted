########################################
# test class for structure
########################################
package Structure;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name self self_array self_hash self_array2 self_hash2 other nonshared);
%AUTODB=(collection=>'Structure',
	 keys=>qq(id int, name string, other object));
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__;
  $self->self($self);
  $self->self_array([$self,$self]);
  $self->self_array2([$self->self_array,$self->self_array]);
  $self->self_hash({key0=>$self,key1=>$self});
  $self->self_hash2({key0=>$self->self_hash,key1=>$self->self_hash});
}

1;
