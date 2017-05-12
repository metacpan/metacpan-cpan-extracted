package autoclass_035::trio::t3;
use base qw(autoclass_035::trio::t2 autoclass_035::external::ext3);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t3');
 }
1;
