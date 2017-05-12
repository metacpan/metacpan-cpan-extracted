package autoclass_032::diamond::d21;
use base qw(Class::AutoClass autoclass_032::diamond::d1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d21');
 }
1;
