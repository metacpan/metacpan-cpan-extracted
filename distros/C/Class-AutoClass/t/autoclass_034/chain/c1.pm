package autoclass_034::chain::c1;
use base qw(Class::AutoClass);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c1');
 }
1;
