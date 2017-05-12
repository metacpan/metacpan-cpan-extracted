package autoclass_039::trio::t2;
use base qw(autoclass_039::trio::t10 autoclass_039::trio::t11);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_t2 dflt_t2);
@OTHER_ATTRIBUTES=qw(other_t2);
@CLASS_ATTRIBUTES=qw(class_t2);
%DEFAULTS=(dflt_t2=>'t2');
%SYNONYMS=(syn_t2=>'auto_t2');
Class::AutoClass::declare;

sub other_t2 {
  my $self=shift;
  @_? $self->{other_t2}=$_[0]: $self->{other_t2};
}
1;
