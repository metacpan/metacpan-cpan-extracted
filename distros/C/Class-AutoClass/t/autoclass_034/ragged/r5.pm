package autoclass_034::ragged::r5;
use base qw(autoclass_034::ragged::r1 autoclass_034::ragged::r20 autoclass_034::ragged::r4);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r5');
 }
1;
