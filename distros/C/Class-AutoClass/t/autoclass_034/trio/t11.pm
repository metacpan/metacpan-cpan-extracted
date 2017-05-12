package autoclass_034::trio::t11;
use base qw(Class::AutoClass autoclass_034::external::ext);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t11');
 }
1;
