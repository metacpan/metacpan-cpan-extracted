package autoclass_030::diamond::d51;
use base qw(autoclass_030::diamond::d4);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d51');
 }
1;
