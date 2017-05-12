package autoclass_020::Parent;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(attr_p real);
@OTHER_ATTRIBUTES=qw(class_p);
@CLASS_ATTRIBUTES=qw(attr_p);
%SYNONYMS=(other_p=>'real');
%DEFAULTS=();
Class::AutoClass::declare;

sub other_p {
  my $self=shift;
  @_? $self->{_other_p}=$_[0]: $self->{_other_p};
}
1;
