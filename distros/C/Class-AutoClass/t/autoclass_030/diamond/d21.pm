package autoclass_030::diamond::d21;
use base qw(autoclass_030::diamond::d1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d21');
 }
1;
