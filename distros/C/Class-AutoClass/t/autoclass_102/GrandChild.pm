package autoclass_102::GrandChild;
use strict;
use Class::AutoClass;
# do NOT use Parent or Child!! this is the whole point of the test!!!
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(autoclass_102::Child);
@AUTO_ATTRIBUTES  = qw(grandchild_attribute grandchild_default);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(grandchild_class_default);
%SYNONYMS         = ();
%DEFAULTS = (
	     grandchild_default => 'grandchild',
	     grandchild_class_default => 'grandchild',
	    );
Class::AutoClass::declare(__PACKAGE__);

1;
