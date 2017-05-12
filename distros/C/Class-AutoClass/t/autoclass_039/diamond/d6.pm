package autoclass_039::diamond::d6;
use base qw(autoclass_039::diamond::d50 autoclass_039::diamond::d51);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d6 dflt_d6);
@OTHER_ATTRIBUTES=qw(other_d6);
@CLASS_ATTRIBUTES=qw(class_d6);
%DEFAULTS=(dflt_d6=>'d6');
%SYNONYMS=(syn_d6=>'auto_d6');
Class::AutoClass::declare;

sub other_d6 {
  my $self=shift;
  @_? $self->{other_d6}=$_[0]: $self->{other_d6};
}
1;
