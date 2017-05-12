package autoclass_039::ragged::r21;
use base qw(autoclass_039::ragged::r1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r21 dflt_r21);
@OTHER_ATTRIBUTES=qw(other_r21);
@CLASS_ATTRIBUTES=qw(class_r21);
%DEFAULTS=(dflt_r21=>'r21');
%SYNONYMS=(syn_r21=>'auto_r21');
Class::AutoClass::declare;

sub other_r21 {
  my $self=shift;
  @_? $self->{other_r21}=$_[0]: $self->{other_r21};
}
1;
