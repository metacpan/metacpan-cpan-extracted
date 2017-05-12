package autoclass_035::diamond::d3;
use base qw(autoclass_035::diamond::d20 autoclass_035::diamond::d21 autoclass_035::external::ext3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d3');
 }
1;
