package autoclass_031::diamond::d51;
use base qw(autoclass_031::diamond::d4);
 
sub new {
  my $self_or_class=shift;
  my $class=ref($self_or_class) || $self_or_class;
  my $self=ref($self_or_class)? $self_or_class: bless {},$class;
  push(@{$self->{new_history}},'d51');
  $self->SUPER::new(@_);
 }

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d51');
 }
1;
