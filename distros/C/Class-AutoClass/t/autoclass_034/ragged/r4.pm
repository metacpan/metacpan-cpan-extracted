package autoclass_034::ragged::r4;
use base qw(autoclass_034::ragged::r20 autoclass_034::ragged::r21 autoclass_034::ragged::r22
	    autoclass_034::ragged::r30 autoclass_034::ragged::r31 autoclass_034::ragged::r32);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r4');
 }
1;
