package autoclass_030::trio::t2;
use base qw(autoclass_030::trio::t10 autoclass_030::trio::t11);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t2');
 }
1;
