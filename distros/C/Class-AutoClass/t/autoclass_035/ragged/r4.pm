package autoclass_035::ragged::r4;
use base qw(autoclass_035::ragged::r20 autoclass_035::ragged::r21 autoclass_035::ragged::r22 autoclass_035::ragged::r30 autoclass_035::ragged::r31 autoclass_035::ragged::r32 autoclass_035::external::ext4);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r4');
 }
1;
