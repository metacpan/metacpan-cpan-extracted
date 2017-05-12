package autoclass_039::diamond::d4;
use base qw(autoclass_039::diamond::d3);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d4 dflt_d4);
@OTHER_ATTRIBUTES=qw(other_d4);
@CLASS_ATTRIBUTES=qw(class_d4);
%DEFAULTS=(dflt_d4=>'d4');
%SYNONYMS=(syn_d4=>'auto_d4');
Class::AutoClass::declare;

sub other_d4 {
  my $self=shift;
  @_? $self->{other_d4}=$_[0]: $self->{other_d4};
}
1;
