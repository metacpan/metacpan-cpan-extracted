package Data::Babel::Base;
use strict;
use Carp;
use Hash::AutoHash::Args qw(autoargs_exists);
use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %AUTODB);
use base qw(Class::AutoClass);
@AUTO_ATTRIBUTES=qw(name babel);
@CLASS_ATTRIBUTES=qw(autodb verbose);
%SYNONYMS=();
Class::AutoClass::declare;

# get object from database if it exists
# arg is object name. can be passed positionally or keyword form
sub old {
  my $class=shift;
  my($name,$autodb);
  if (@_==1 && !ref $_[0]) {
    $name=$_[0];
    # NG 10-11-14: move below 'else' so will be set by keyword form, too
    # $autodb=$class->autodb;
  } else {
    my $args=new Hash::AutoHash::Args(@_);
    my $verbose;
    ($name,$autodb,$verbose)=@$args{qw(name autodb verbose)}; # okay for autodb,... to be absent
    $class->autodb($autodb) if $autodb;
    $class->verbose($verbose) if $verbose;
  }
  $autodb or $autodb=$class->autodb;
  confess "Missing argument to 'old': name" unless $name;
  confess "Cannot run 'old': autodb not set" unless $autodb;
  my($old_self)=$autodb->get(collection=>class2coll($class),name=>$name);
#   if ($old_self && $args) {
#     # set class attributes from args
#     $old_self->set_attributes([qw(autodb log verbose)],$args);
#   }
  $old_self;
}
# sub autodb {$main::autodb}
# sub log {$main::log}
# sub verbose {$main::verbose}

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $name=$self->name; 
  my $autodb=$self->autodb;
  confess "Missing argument to 'new': name" unless $name;
  # NG 10-08-24: okay for autodb to be unset, esp. when creating component objects
  #              thanks to Denise for finding this bug!
  # confess "Missing argument to 'new': autodb" unless $autodb;
  my $old_self;
  if (autoargs_exists($args,'old')) { # caller already ran 'old'. use what he got
    $old_self=$args->old;
  } elsif ($autodb) {		      # else do it here if $autodb set
    ($old_self)=$autodb->get(collection=>class2coll(ref $self),name=>$self->name);
  }
  if ($old_self) {
    # 'renew' old object by copying new self on top of old.
    # this is all so we'll re-use the oid...
    %$old_self=%$self;
    $self=$self->{__OVERRIDE__}=$old_self; # return old
  } elsif ($args->must_exist) {	# object must exist but doesn't. error
    confess "$class object".($name? " named $name": '')." not found in database";
  # } else {                      # first time through. call class-specific _init_first
    # $self->_init_first($args)
  }
}

# unique ids that are persistent and can be converted back to object
# used as node ids by IdType, MapTable, Master
sub id {
  my $self=shift;
  my($prefix)=ref($self)=~/^.*::(\w+)$/; # extract last component of class
  return join(':',lc $prefix,$self->name);
}

sub class2coll {
  my $self_or_class=shift;
  my $class=(ref $self_or_class) || $self_or_class;
  my($coll)=$class=~/^Data::Babel(?:::){0,1}(.*)$/;
  $coll || 'Babel';
}

1;
