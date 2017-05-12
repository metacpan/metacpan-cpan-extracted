package autoclass_034::diamond::d20;
use base qw(autoclass_034::diamond::d1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d20');
 }
1;
