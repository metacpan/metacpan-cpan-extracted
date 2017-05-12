package autoclass_030::ragged::r30;
use base qw(autoclass_030::ragged::r20);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r30');
 }
1;
