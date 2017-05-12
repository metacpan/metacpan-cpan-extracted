package autoclass_032::ragged::r31;
use base qw(Class::AutoClass autoclass_032::ragged::r21);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r31');
 }
1;
