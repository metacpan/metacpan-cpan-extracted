package autoclass_031::chain::c1;
use base qw(Class::AutoClass);
 
sub new {
  my $self_or_class=shift;
  my $class=ref($self_or_class) || $self_or_class;
  my $self=ref($self_or_class)? $self_or_class: bless {},$class;
  push(@{$self->{new_history}},'c1');
  $self->SUPER::new(@_);
 }

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c1');
 }
1;
