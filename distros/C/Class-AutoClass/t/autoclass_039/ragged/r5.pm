package autoclass_039::ragged::r5;
use base qw(autoclass_039::ragged::r1 autoclass_039::ragged::r20 autoclass_039::ragged::r4);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r5 dflt_r5);
@OTHER_ATTRIBUTES=qw(other_r5);
@CLASS_ATTRIBUTES=qw(class_r5);
%DEFAULTS=(dflt_r5=>'r5');
%SYNONYMS=(syn_r5=>'auto_r5');
Class::AutoClass::declare;

sub other_r5 {
  my $self=shift;
  @_? $self->{other_r5}=$_[0]: $self->{other_r5};
}
1;
