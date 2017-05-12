package autoclass_034::ragged::r32;
use base qw(autoclass_034::ragged::r22);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r32');
 }
1;
