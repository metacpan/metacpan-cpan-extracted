package autoclass_035::chain::c2;
use base qw(autoclass_035::chain::c1 autoclass_035::external::ext2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'c2');
 }
1;
