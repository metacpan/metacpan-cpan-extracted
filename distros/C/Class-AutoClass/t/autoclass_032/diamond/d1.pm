package autoclass_032::diamond::d1;
use base qw(Class::AutoClass);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d1');
 }
1;
