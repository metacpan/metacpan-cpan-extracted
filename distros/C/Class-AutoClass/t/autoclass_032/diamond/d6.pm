package autoclass_032::diamond::d6;
use base qw(Class::AutoClass autoclass_032::diamond::d50 autoclass_032::diamond::d51);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d6');
 }
1;
