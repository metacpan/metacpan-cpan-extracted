package autoclass_039::ragged::r30;
use base qw(autoclass_039::ragged::r20);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r30 dflt_r30);
@OTHER_ATTRIBUTES=qw(other_r30);
@CLASS_ATTRIBUTES=qw(class_r30);
%DEFAULTS=(dflt_r30=>'r30');
%SYNONYMS=(syn_r30=>'auto_r30');
Class::AutoClass::declare;

sub other_r30 {
  my $self=shift;
  @_? $self->{other_r30}=$_[0]: $self->{other_r30};
}
1;
