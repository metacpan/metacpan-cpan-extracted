package autoclass_035::chain::c3;
use base qw(autoclass_035::chain::c2 autoclass_035::external::ext3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c3');
 }
1;
