package autoclass_034::diamond::d3;
use base qw(autoclass_034::diamond::d20 autoclass_034::diamond::d21);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d3');
 }
1;
