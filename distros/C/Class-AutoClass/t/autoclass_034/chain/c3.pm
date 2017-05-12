package autoclass_034::chain::c3;
use base qw(autoclass_034::chain::c2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c3');
 }
1;
