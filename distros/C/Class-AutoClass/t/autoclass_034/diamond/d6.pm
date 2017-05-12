package autoclass_034::diamond::d6;
use base qw(autoclass_034::diamond::d50 autoclass_034::diamond::d51);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d6');
 }
1;
