# classes for 015.freeze_thaw test. updated version of Chris's dd_freeze_thaw.t
# tests freeze/thaw behavior of our modified Dumper

########################################
## base package for test classes. declares attributes. 
## initializes 'fresh' and various ref attributes
########################################
package root;
use strict;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES=qw(name fresh fill freeze_thaw freeze freeze2thaw thaw nada);
%DEFAULTS=(fresh=>'fresh',fill=>0);
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $name=$self->name;
  $self->set(freeze_thaw=>new freeze_thaw(name=>"from $name"),
	     freeze=>new freeze(name=>"from $name"),
	     freeze2thaw=>new freeze2thaw(name=>"from $name"),
	     thaw=>new thaw(name=>"from $name"),
	     nada=>new nada(name=>"from $name"),) if $self->fill;
}
########################################
## freeze_thaw package - has DUMPER_freeze, DUMPER_thaw
########################################
package freeze_thaw;
use strict;
use base qw(root);
use Test::More;

# NG 10-01-01: modified to leave $self unchanged and return desired new value
sub DUMPER_freeze {
  my($self)=@_;
  # note(">>> DUMPER_freeze");
  my $copy=bless {},ref $self;
  # force shallow copy
  %$copy=%$self;
  $copy->fresh('nope. frozen and thawed');
  return $copy;
}
sub DUMPER_thaw {
  my($self)=@_;
  # note("<<< DUMPER_thaw");
  return $self;
}
########################################
## freeze package - has DUMPER_freeze, no DUMPER_thaw
########################################
package freeze;
use strict;
use base qw(root);
use Test::More;

# NG 10-01-01: modified to leave $self unchanged and return desired new value
sub DUMPER_freeze {
  my($self)=@_;
  # note(">>> DUMPER_freeze");
  my $copy=bless {},ref $self;
  # force shallow copy
  %$copy=%$self;
  $copy->fresh('nope. frozen and thawed');
  return $copy;
}
########################################
## freeze2thaw package - has DUMPER_freeze (emits 'thaw' object), no DUMPER_thaw
########################################
package freeze2thaw;
use strict;
use base qw(root);
use Test::More;

# NG 10-01-01: modified to leave $self unchanged and return desired new value
sub DUMPER_freeze {
  my($self)=@_;
  # note(">>> DUMPER_freeze");
  my $copy=bless {},'thaw';
  # force shallow copy
  %$copy=%$self;
  $copy->fresh('nope. frozen and thawed');
  return $copy;
}
########################################
## thaw package - no DUMPER_freeze, yes DUMPER_thaw
########################################
package thaw;
use strict;
use base qw(root);
use Test::More;

sub DUMPER_thaw {
  my($self)=@_;
  # note("<<< DUMPER_thaw");
  return $self;
}

########################################
## nada package  (no DUMPER_freeze, DUMPER_thaw method)
########################################
package nada;
use strict;
use base qw(root);
use Test::More;

1;
