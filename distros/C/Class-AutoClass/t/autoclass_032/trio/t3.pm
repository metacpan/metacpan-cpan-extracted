package autoclass_032::trio::t3;
use base qw(Class::AutoClass autoclass_032::trio::t2);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t3');
 }
1;
