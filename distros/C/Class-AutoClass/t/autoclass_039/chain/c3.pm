package autoclass_039::chain::c3;
use base qw(autoclass_039::chain::c2);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_c3 dflt_c3);
@OTHER_ATTRIBUTES=qw(other_c3);
@CLASS_ATTRIBUTES=qw(class_c3);
%DEFAULTS=(dflt_c3=>'c3');
%SYNONYMS=(syn_c3=>'auto_c3');
Class::AutoClass::declare;

sub other_c3 {
  my $self=shift;
  @_? $self->{other_c3}=$_[0]: $self->{other_c3};
}
1;
