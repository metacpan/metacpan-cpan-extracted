package autoclass_032::ragged::r1;
use base qw(Class::AutoClass);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r1');
 }
1;
