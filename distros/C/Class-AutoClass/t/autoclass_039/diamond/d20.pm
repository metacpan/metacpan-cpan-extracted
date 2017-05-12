package autoclass_039::diamond::d20;
use base qw(autoclass_039::diamond::d1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d20 dflt_d20);
@OTHER_ATTRIBUTES=qw(other_d20);
@CLASS_ATTRIBUTES=qw(class_d20);
%DEFAULTS=(dflt_d20=>'d20');
%SYNONYMS=(syn_d20=>'auto_d20');
Class::AutoClass::declare;

sub other_d20 {
  my $self=shift;
  @_? $self->{other_d20}=$_[0]: $self->{other_d20};
}
1;
