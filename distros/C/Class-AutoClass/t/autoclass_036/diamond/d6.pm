package autoclass_036::diamond::d6;
use base qw(autoclass_036::diamond::d50 autoclass_036::diamond::d51);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw();
@OTHER_ATTRIBUTES=qw();
@CLASS_ATTRIBUTES=qw();
%DEFAULTS=();
%SYNONYMS=();
Class::AutoClass::declare;

sub _init_self {
   my($self,$class,$args)=@_;
   push(@{$self->{init_self_history}},'d6');
 }
1;
