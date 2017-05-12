package autoclass_030::trio::t10;
use base qw(Class::AutoClass);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t10');
 }
1;
