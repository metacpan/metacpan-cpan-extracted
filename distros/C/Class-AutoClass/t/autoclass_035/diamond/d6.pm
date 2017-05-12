package autoclass_035::diamond::d6;
use base qw(autoclass_035::diamond::d50 autoclass_035::diamond::d51 autoclass_035::external::ext6);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d6');
 }
1;
