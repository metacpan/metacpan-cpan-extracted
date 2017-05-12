package autoclass_032::ragged::r30;
use base qw(Class::AutoClass autoclass_032::ragged::r20);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r30');
 }
1;
