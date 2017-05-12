package autoclass_106::Parent;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(real);
@OTHER_ATTRIBUTES = qw();
@CLASS_ATTRIBUTES = qw();
%SYNONYMS         = ( syn1=>'real', syn2=>'real' );
%DEFAULTS = ();

Class::AutoClass::declare(__PACKAGE__);

1;
