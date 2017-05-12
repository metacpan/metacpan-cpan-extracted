package autoclass_039::diamond::d50;
use base qw(autoclass_039::diamond::d4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d50 dflt_d50);
@OTHER_ATTRIBUTES=qw(other_d50);
@CLASS_ATTRIBUTES=qw(class_d50);
%DEFAULTS=(dflt_d50=>'d50');
%SYNONYMS=(syn_d50=>'auto_d50');
Class::AutoClass::declare;

sub other_d50 {
  my $self=shift;
  @_? $self->{other_d50}=$_[0]: $self->{other_d50};
}
1;
