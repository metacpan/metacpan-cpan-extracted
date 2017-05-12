package autoclass_011::Nullable;

use strict;
use Class::AutoClass;
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
  if (defined $args->a) {
  	return $self
  } else {
  	$self->{__NULLIFY__}=1; # undef the entire object
  	return undef;
  }
}


1;
