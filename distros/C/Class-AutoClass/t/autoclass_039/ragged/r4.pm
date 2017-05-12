package autoclass_039::ragged::r4;
use base qw(autoclass_039::ragged::r20 autoclass_039::ragged::r21 autoclass_039::ragged::r22 autoclass_039::ragged::r30 autoclass_039::ragged::r31 autoclass_039::ragged::r32);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r4 dflt_r4);
@OTHER_ATTRIBUTES=qw(other_r4);
@CLASS_ATTRIBUTES=qw(class_r4);
%DEFAULTS=(dflt_r4=>'r4');
%SYNONYMS=(syn_r4=>'auto_r4');
Class::AutoClass::declare;

sub other_r4 {
  my $self=shift;
  @_? $self->{other_r4}=$_[0]: $self->{other_r4};
}
1;
