package autoclass_035::ragged::r5;
use base qw(autoclass_035::ragged::r1 autoclass_035::ragged::r20 autoclass_035::ragged::r4 autoclass_035::external::ext5);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r5');
 }
1;
