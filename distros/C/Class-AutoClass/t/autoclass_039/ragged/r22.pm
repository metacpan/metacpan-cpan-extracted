package autoclass_039::ragged::r22;
use base qw(autoclass_039::ragged::r1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r22 dflt_r22);
@OTHER_ATTRIBUTES=qw(other_r22);
@CLASS_ATTRIBUTES=qw(class_r22);
%DEFAULTS=(dflt_r22=>'r22');
%SYNONYMS=(syn_r22=>'auto_r22');
Class::AutoClass::declare;

sub other_r22 {
  my $self=shift;
  @_? $self->{other_r22}=$_[0]: $self->{other_r22};
}
1;
