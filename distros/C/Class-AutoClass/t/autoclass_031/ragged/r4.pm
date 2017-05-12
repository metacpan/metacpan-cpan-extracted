package autoclass_031::ragged::r4;
use base qw(autoclass_031::ragged::r20 autoclass_031::ragged::r21 autoclass_031::ragged::r22
	    autoclass_031::ragged::r30 autoclass_031::ragged::r31 autoclass_031::ragged::r32);
 
sub new {
  my $self_or_class=shift;
  my $class=ref($self_or_class) || $self_or_class;
  my $self=ref($self_or_class)? $self_or_class: bless {},$class;
  push(@{$self->{new_history}},'r4');
  $self->SUPER::new(@_);
 }

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r4');
 }
1;
