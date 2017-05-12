package autoclass_030::ragged::r4;
use base qw(autoclass_030::ragged::r20 autoclass_030::ragged::r21 autoclass_030::ragged::r22 autoclass_030::ragged::r30 autoclass_030::ragged::r31 autoclass_030::ragged::r32);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r4');
 }
1;
