package autoclass_035::diamond::d7;
use base qw(autoclass_035::diamond::d6 autoclass_035::external::ext7);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d7');
 }
1;
