########################################
# test classes for basics pnp (persistent-nonpersistent)
########################################
package NonPersistent00;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES);
@AUTO_ATTRIBUTES=qw(id name p0 p1 np0 np1);
Class::AutoClass::declare;

sub fini {
  my $self=shift;
  my($p0,$p1,$np0,$np1)=@_;
  $self->p0($p0); 
  $self->p1($p1); 
  $self->np0($np0); 
  $self->np1($np1);
  $self;
}
1;
