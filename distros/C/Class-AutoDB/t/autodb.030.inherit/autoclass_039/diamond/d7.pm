package autoclass_039::diamond::d7;
use base qw(autoclass_039::diamond::d6);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d7 dflt_d7);
@OTHER_ATTRIBUTES=qw(other_d7);
@CLASS_ATTRIBUTES=qw(class_d7);
%DEFAULTS=(dflt_d7=>'d7');
%SYNONYMS=(syn_d7=>'auto_d7');
Class::AutoClass::declare;

sub other_d7 {
  my $self=shift;
  @_? $self->{other_d7}=$_[0]: $self->{other_d7};
}
1;
