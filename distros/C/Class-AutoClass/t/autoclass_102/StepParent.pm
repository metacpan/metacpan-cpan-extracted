package autoclass_102::StepParent;
use strict;
use Class::AutoClass;
use autoclass_102::Child;	  # MUST not use Parent,Child,GrandChild

use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(stepparent_attribute stepparent_default);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(stepparent_class_default);
%SYNONYMS         = ();
%DEFAULTS = (
	     stepparent_default => 'stepparent',
	     stepparent_class_default => 'stepparent',
	    );
Class::AutoClass::declare(__PACKAGE__);

1;
