package autoclass_035::ragged::r31;
use base qw(autoclass_035::ragged::r21 autoclass_035::external::ext3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r31');
 }
1;
