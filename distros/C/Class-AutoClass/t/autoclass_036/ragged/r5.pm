package autoclass_036::ragged::r5;
use base qw(autoclass_036::ragged::r1 autoclass_036::ragged::r20 autoclass_036::ragged::r4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw();
@OTHER_ATTRIBUTES=qw();
@CLASS_ATTRIBUTES=qw();
%DEFAULTS=();
%SYNONYMS=();
Class::AutoClass::declare;

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'r5');
 }
1;
