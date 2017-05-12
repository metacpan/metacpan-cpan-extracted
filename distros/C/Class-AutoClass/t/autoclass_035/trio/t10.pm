package autoclass_035::trio::t10;
use base qw(Class::AutoClass autoclass_035::external::ext1);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'t10');
 }
1;
