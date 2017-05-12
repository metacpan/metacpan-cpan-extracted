package autoclass_032::diamond::d4;
use base qw(Class::AutoClass autoclass_032::diamond::d3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d4');
 }
1;
