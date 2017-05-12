package autoclass_039::ragged::r32;
use base qw(autoclass_039::ragged::r22);
 
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(auto_r32 dflt_r32);
@OTHER_ATTRIBUTES=qw(other_r32);
@CLASS_ATTRIBUTES=qw(class_r32);
%DEFAULTS=(dflt_r32=>'r32');
%SYNONYMS=(syn_r32=>'auto_r32');
Class::AutoClass::declare;

sub other_r32 {
  my $self=shift;
  @_? $self->{other_r32}=$_[0]: $self->{other_r32};
}
1;
