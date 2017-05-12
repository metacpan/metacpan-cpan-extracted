package autoclass_030::ragged::r31;
use base qw(autoclass_030::ragged::r21);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r31');
 }
1;
