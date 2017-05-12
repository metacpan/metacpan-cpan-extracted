package autoclass_103::GrandChild;
use strict;
use Class::AutoClass;
use Parent;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(autoclass_103::Child);
@AUTO_ATTRIBUTES  = qw();
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(species);
%SYNONYMS         = ();
%DEFAULTS         = ( a => 'grandchild', 
		      b => 'virtual grandchild', 
		      d => 'default set in grandchild for attribute defined in parent',
		      species => 'schmoo' );
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
 my ( $self, $class, $args ) = @_;
 return
   unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
}
1;
