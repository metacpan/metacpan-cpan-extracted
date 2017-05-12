package autoclass_030::ragged::r5;
use base qw(autoclass_030::ragged::r1 autoclass_030::ragged::r20 autoclass_030::ragged::r4);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r5');
 }
1;
