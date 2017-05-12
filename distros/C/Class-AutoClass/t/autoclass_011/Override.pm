package autoclass_011::Override;

use strict;
use Class::AutoClass;
use Child;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(a);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  if($args->override){
     my $p = new Child;
     $self->{__OVERRIDE__}=$p; # retrun a different object than expected
  } else {
    return $self
  }
}


1;
