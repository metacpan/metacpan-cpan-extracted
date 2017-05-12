package autoclass_039::diamond::d3;
use base qw(autoclass_039::diamond::d20 autoclass_039::diamond::d21);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d3 dflt_d3);
@OTHER_ATTRIBUTES=qw(other_d3);
@CLASS_ATTRIBUTES=qw(class_d3);
%DEFAULTS=(dflt_d3=>'d3');
%SYNONYMS=(syn_d3=>'auto_d3');
Class::AutoClass::declare;

sub other_d3 {
  my $self=shift;
  @_? $self->{other_d3}=$_[0]: $self->{other_d3};
}
1;
