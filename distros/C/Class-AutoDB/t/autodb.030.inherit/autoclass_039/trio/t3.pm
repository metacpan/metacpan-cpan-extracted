package autoclass_039::trio::t3;
use base qw(autoclass_039::trio::t2);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_t3 dflt_t3);
@OTHER_ATTRIBUTES=qw(other_t3);
@CLASS_ATTRIBUTES=qw(class_t3);
%DEFAULTS=(dflt_t3=>'t3');
%SYNONYMS=(syn_t3=>'auto_t3');
Class::AutoClass::declare;

sub other_t3 {
  my $self=shift;
  @_? $self->{other_t3}=$_[0]: $self->{other_t3};
}
1;
