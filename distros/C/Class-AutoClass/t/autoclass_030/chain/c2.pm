package autoclass_030::chain::c2;
use base qw(autoclass_030::chain::c1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c2');
 }
1;
