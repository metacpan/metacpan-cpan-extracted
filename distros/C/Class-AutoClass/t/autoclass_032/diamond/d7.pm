package autoclass_032::diamond::d7;
use base qw(Class::AutoClass autoclass_032::diamond::d6);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d7');
 }
1;
