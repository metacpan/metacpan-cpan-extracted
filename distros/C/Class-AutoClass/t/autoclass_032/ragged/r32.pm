package autoclass_032::ragged::r32;
use base qw(Class::AutoClass autoclass_032::ragged::r22);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r32');
 }
1;
