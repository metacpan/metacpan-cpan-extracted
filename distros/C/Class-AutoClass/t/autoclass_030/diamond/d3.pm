package autoclass_030::diamond::d3;
use base qw(autoclass_030::diamond::d20 autoclass_030::diamond::d21);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d3');
 }
1;
