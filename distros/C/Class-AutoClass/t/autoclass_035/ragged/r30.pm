package autoclass_035::ragged::r30;
use base qw(autoclass_035::ragged::r20 autoclass_035::external::ext3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r30');
 }
1;
