########################################
# test classes for basics selfcircular
########################################
package SelfCircular;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name self self_array self_hash self_array2 self_hash2);
%AUTODB=(collection=>'SelfCircular',
	 keys=>qq(id int,name string, self object,self_array list(object)));
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__;
  $self->self($self);
  $self->self_array([$self,$self]);
  $self->self_array2([$self->self_array,$self->self_array]);
  $self->self_hash({key1=>$self,key2=>$self});
  $self->self_hash2({key1=>$self->self_hash,key2=>$self->self_hash});
}

1;
