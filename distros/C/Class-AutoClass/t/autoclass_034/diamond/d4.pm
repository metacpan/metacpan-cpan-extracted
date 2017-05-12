package autoclass_034::diamond::d4;
use base qw(autoclass_034::diamond::d3 autoclass_034::external::ext);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d4');
 }
1;
