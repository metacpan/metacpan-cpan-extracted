package autoclass_034::ragged::r22;
use base qw(autoclass_034::ragged::r1 autoclass_034::external::ext);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r22');
 }
1;
