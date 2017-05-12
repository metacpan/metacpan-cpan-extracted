package autoclass_035::ragged::r32;
use base qw(autoclass_035::ragged::r22 autoclass_035::external::ext3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r32');
 }
1;
