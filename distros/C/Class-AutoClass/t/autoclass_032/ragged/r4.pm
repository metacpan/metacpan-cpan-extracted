package autoclass_032::ragged::r4;
use base qw(Class::AutoClass autoclass_032::ragged::r20 autoclass_032::ragged::r21 autoclass_032::ragged::r22
	    autoclass_032::ragged::r30 autoclass_032::ragged::r31 autoclass_032::ragged::r32);
 
sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r4');
 }
1;
