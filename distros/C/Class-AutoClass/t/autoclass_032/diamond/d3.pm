package autoclass_032::diamond::d3;
use base qw(Class::AutoClass autoclass_032::diamond::d20 autoclass_032::diamond::d21);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d3');
 }
1;
