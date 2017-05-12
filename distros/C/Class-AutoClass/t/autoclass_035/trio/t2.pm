package autoclass_035::trio::t2;
use base qw(autoclass_035::trio::t10 autoclass_035::trio::t11 autoclass_035::external::ext2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t2');
 }
1;
