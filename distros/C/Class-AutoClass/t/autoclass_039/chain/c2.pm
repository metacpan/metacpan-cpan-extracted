package autoclass_039::chain::c2;
use base qw(autoclass_039::chain::c1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_c2 dflt_c2);
@OTHER_ATTRIBUTES=qw(other_c2);
@CLASS_ATTRIBUTES=qw(class_c2);
%DEFAULTS=(dflt_c2=>'c2');
%SYNONYMS=(syn_c2=>'auto_c2');
Class::AutoClass::declare;

sub other_c2 {
  my $self=shift;
  @_? $self->{other_c2}=$_[0]: $self->{other_c2};
}
1;
