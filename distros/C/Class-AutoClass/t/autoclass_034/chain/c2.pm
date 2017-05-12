package autoclass_034::chain::c2;
use base qw(autoclass_034::chain::c1 autoclass_034::external::ext);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c2');
 }
1;
