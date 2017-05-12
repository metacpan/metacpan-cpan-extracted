package autoclass_038::trio::t11;
use base qw(Class::AutoClass);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw();
@OTHER_ATTRIBUTES=qw();
@CLASS_ATTRIBUTES=qw();
%DEFAULTS=();
%SYNONYMS=();
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  my($base)=$class=~/::(\w+)$/;
  push(@{$self->{init_self_history}},$base);
}
1;
