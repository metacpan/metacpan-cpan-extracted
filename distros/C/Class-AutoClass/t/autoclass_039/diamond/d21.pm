package autoclass_039::diamond::d21;
use base qw(autoclass_039::diamond::d1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d21 dflt_d21);
@OTHER_ATTRIBUTES=qw(other_d21);
@CLASS_ATTRIBUTES=qw(class_d21);
%DEFAULTS=(dflt_d21=>'d21');
%SYNONYMS=(syn_d21=>'auto_d21');
Class::AutoClass::declare;

sub other_d21 {
  my $self=shift;
  @_? $self->{other_d21}=$_[0]: $self->{other_d21};
}
1;
