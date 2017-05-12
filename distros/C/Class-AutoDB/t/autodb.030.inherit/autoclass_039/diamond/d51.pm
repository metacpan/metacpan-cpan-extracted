package autoclass_039::diamond::d51;
use base qw(autoclass_039::diamond::d4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_d51 dflt_d51);
@OTHER_ATTRIBUTES=qw(other_d51);
@CLASS_ATTRIBUTES=qw(class_d51);
%DEFAULTS=(dflt_d51=>'d51');
%SYNONYMS=(syn_d51=>'auto_d51');
Class::AutoClass::declare;

sub other_d51 {
  my $self=shift;
  @_? $self->{other_d51}=$_[0]: $self->{other_d51};
}
1;
