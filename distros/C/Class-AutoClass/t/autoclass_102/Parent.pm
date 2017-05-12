package autoclass_102::Parent;
use strict;
use Class::AutoClass;
use autoclass_102::Child;	  # MUST use Child -- whole point of test!
use autoclass_102::GrandChild; # MUST use GrandChild -- whole point of test!
use autoclass_102::StepParent; # MUST use this kast -- whole point of test!

use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(parent_attribute parent_default);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(parent_class_default);
%SYNONYMS         = ();
%DEFAULTS = (
	     parent_default => 'parent',
	     parent_class_default => 'parent',
	    );
Class::AutoClass::declare(__PACKAGE__);

1;
