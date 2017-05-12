package autoclass_032::chain::c2;
use base qw(Class::AutoClass autoclass_032::chain::c1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c2');
 }
1;
