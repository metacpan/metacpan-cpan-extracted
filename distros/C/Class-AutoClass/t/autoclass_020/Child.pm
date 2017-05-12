package autoclass_020::Child;
use strict;
use base qw(autoclass_020::Parent);
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(attr_c);
@OTHER_ATTRIBUTES=qw();
@CLASS_ATTRIBUTES=qw(class_c);
%SYNONYMS=(syn=>'attr_c');
%DEFAULTS=(syn=>'child default');
Class::AutoClass::declare;

sub other_c {
  my $self=shift;
  @_? $self->{_other_c}=$_[0]: $self->{_other_c};
}
1;
