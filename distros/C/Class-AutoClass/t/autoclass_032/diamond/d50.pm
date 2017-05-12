package autoclass_032::diamond::d50;
use base qw(Class::AutoClass autoclass_032::diamond::d4);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d50');
 }
1;
