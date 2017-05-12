package autoclass_010::Parent;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(auto real auto_dflt real_dflt);
@OTHER_ATTRIBUTES = qw(other other_dflt);
@CLASS_ATTRIBUTES = qw(class class_dflt);
%SYNONYMS = (syn=>'real',syn_dflt=>'real_dflt' );
%DEFAULTS = (auto_dflt => 'auto attribute default',
	     other_dflt=> 'other attribute default',
	     class_dflt => 'class attribute default',
	     real_dflt => 'real default',
	     syn_dflt => 'synonym default',
	    );
Class::AutoClass::declare;

sub other {
  my $self=shift;
  push(@{$self->{_other}},@_) if @_; # need 'if' to prevent auto-vivification on 'get'
  $self->{_other};
}
sub other_dflt {
  my $self=shift;
  push(@{$self->{_other_dflt}},@_) if @_; # need 'if' to prevent auto-vivification on 'get'
  $self->{_other_dflt};
}
1;
