package autoclass_035::diamond::d50;
use base qw(autoclass_035::diamond::d4 autoclass_035::external::ext5);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d50');
 }
1;
