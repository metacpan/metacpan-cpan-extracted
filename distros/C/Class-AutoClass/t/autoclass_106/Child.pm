package autoclass_106::Child;
use strict;
use Class::AutoClass;
use Parent;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(autoclass_106::Parent);
@AUTO_ATTRIBUTES  = qw();
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw(species class_hash);
%SYNONYMS         = (syn3=>'real', syn4=>'real');
%DEFAULTS = (
              real => 'default',
	    );
Class::AutoClass::declare(__PACKAGE__);

1;
