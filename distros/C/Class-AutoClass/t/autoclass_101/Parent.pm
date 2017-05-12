package autoclass_101::Parent;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(auto_p real_p);
@OTHER_ATTRIBUTES = qw(other_p);
@CLASS_ATTRIBUTES = qw(class_p);
%SYNONYMS         = (syn_p=>'real_p');
%DEFAULTS = (auto_p       => 'parent auto attribute',
	     other_p      => 'parent other attribute',
	     class_p      => 'parent class attribute',
	     real_p       => 'parent target of synonym',
	     syn_p        => 'parent synonym',
	    );
Class::AutoClass::declare;

sub other_p {
  my $self=shift;
  @_? $self->{_other_p}=$_[0]: $self->{_other_p};
}
1;
