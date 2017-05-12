########################################
# test classes for basics pnp (persistent-nonpersistent)
########################################
package NonPersistent02;
use strict;
use base qw(NonPersistent00);
use vars qw(@AUTO_ATTRIBUTES);
@AUTO_ATTRIBUTES=qw(p_array p_hash p_array2 p_hash2 p_nonshared 
		    np_array np_hash np_array2 np_hash2 np_nonshared);
Class::AutoClass::declare;

sub fini {
  my $self=shift;
  my($p0,$p1,$np0,$np1,$p_nonshared,$np_nonshared)=@_;
  $self->SUPER::fini(@_);

  $self->p_array([$p0,$p1]);
  $self->p_array2([$self->p_array,$self->p_array]);
  $self->p_hash({p0=>$p0,p1=>$p1});
  $self->p_hash2({key0=>$self->p_hash,key1=>$self->p_hash});
  
  $self->np_array([$np0,$np1]);
  $self->np_array2([$self->np_array,$self->np_array]);
  $self->np_hash({np0=>$np0,np1=>$np1});
  $self->np_hash2({key0=>$self->np_hash,key1=>$self->np_hash});

  $self->p_nonshared($p_nonshared);
  $self->np_nonshared($np_nonshared);
  
}
1;
