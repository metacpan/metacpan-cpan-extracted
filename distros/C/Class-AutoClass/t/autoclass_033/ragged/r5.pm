package autoclass_033::ragged::r5;
use base qw(Class::AutoClass autoclass_033::ragged::r1 autoclass_033::ragged::r20 autoclass_033::ragged::r4);
 
sub new {
  my $self_or_class=shift;
  my $class=ref($self_or_class) || $self_or_class;
  my $self=ref($self_or_class)? $self_or_class: bless {},$class;
  push(@{$self->{new_history}},'r5');
  $self->SUPER::new(@_);
 }

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r5');
 }
1;
