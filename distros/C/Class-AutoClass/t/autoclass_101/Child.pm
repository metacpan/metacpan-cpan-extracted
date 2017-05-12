package autoclass_101::Child;
use strict;
use Class::AutoClass;
# use Parent;  # do NOT use Parent!! this is the whole point of the test!!!
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass autoclass_101::Parent);
@AUTO_ATTRIBUTES  = qw(auto_c real_c);
@OTHER_ATTRIBUTES = qw(other_c);
@CLASS_ATTRIBUTES = qw(class_c);
%SYNONYMS         = (syn_c=>'real_c');
%DEFAULTS = (auto_c       => 'child auto attribute',
	     other_c      => 'child other attribute',
	     class_c      => 'child class attribute',
	     real_c       => 'child target of synonym',
	     syn_c        => 'child synonym',
	    );
Class::AutoClass::declare;

sub other_c {
  my $self=shift;
  @_? $self->{_other_c}=$_[0]: $self->{_other_c};
}
1;
