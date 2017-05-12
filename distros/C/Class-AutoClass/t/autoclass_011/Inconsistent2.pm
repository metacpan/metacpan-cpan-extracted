package autoclass_011::Inconsistent2;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(autoclass_011::Inconsistent1);
@AUTO_ATTRIBUTES  = qw(b);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(a);
%SYNONYMS         = ( );
%DEFAULTS = ();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
 my ( $self, $class, $args ) = @_;
 return
   unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this

}
1;
