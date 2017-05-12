package autoclass_035::diamond::d21;
use base qw(autoclass_035::diamond::d1 autoclass_035::external::ext2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d21');
 }
1;
