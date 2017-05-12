package autoclass_039::ragged::r31;
use base qw(autoclass_039::ragged::r21);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r31 dflt_r31);
@OTHER_ATTRIBUTES=qw(other_r31);
@CLASS_ATTRIBUTES=qw(class_r31);
%DEFAULTS=(dflt_r31=>'r31');
%SYNONYMS=(syn_r31=>'auto_r31');
Class::AutoClass::declare;

sub other_r31 {
  my $self=shift;
  @_? $self->{other_r31}=$_[0]: $self->{other_r31};
}
1;
