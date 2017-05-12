package autoclass_035::diamond::d4;
use base qw(autoclass_035::diamond::d3 autoclass_035::external::ext4);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d4');
 }
1;
