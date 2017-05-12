package autoclass_030::diamond::d7;
use base qw(autoclass_030::diamond::d6);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d7');
 }
1;
