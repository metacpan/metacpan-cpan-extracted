package autoclass_032::trio::t2;
use base qw(Class::AutoClass autoclass_032::trio::t10 autoclass_032::trio::t11);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t2');
 }
1;
