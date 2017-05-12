package autoclass_104::Child_default_syn;
use strict;
use Class::AutoClass;
use Parent;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Parent);
@AUTO_ATTRIBUTES  = qw(c);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(species class_hash);
%SYNONYMS         = ();
%DEFAULTS = (
              a          => 'child',
              b          => 'virtual child',
	      syn        => 'default',
              class_hash => {
                              bird  => 'robin',
                              these => 'them',
              },
);
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
 my ( $self, $class, $args ) = @_;
 return
   unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
}
1;
