package autoclass_039::ragged::r20;
use base qw(autoclass_039::ragged::r1);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r20 dflt_r20);
@OTHER_ATTRIBUTES=qw(other_r20);
@CLASS_ATTRIBUTES=qw(class_r20);
%DEFAULTS=(dflt_r20=>'r20');
%SYNONYMS=(syn_r20=>'auto_r20');
Class::AutoClass::declare;

sub other_r20 {
  my $self=shift;
  @_? $self->{other_r20}=$_[0]: $self->{other_r20};
}
1;
