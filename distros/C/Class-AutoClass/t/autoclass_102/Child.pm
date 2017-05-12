package autoclass_102::Child;
use strict;
use Class::AutoClass;
# do NOT use Parent or GrandChild!! this is the whole point of the test!!!
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(autoclass_102::Parent autoclass_102::StepParent);
@AUTO_ATTRIBUTES  = qw(child_attribute child_default);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(child_class_default);
%SYNONYMS         = ();
%DEFAULTS = (
	     child_default => 'child',
	     child_class_default => 'child',
	    );
Class::AutoClass::declare(__PACKAGE__);

1;
