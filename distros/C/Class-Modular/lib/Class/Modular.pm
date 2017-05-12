# This module is part of DA, Don Armstrong's Modules, and is released
# under the terms of the GPL version 2, or any later version. See the
# file README and COPYING for more information.
# Copyright 2003,2005 by Don Armstrong <don@donarmstrong.com>.
# $Id: Modular.pm 45 2006-11-17 22:30:15Z don $

package Class::Modular;

=head1 NAME

Class::Modular -- Modular class generation superclass

=head1 SYNOPSIS

     package Foo;

     use base qw(Class::Modular);

     use vars (@METHODS);
     BEGIN{@METHODS=qw(blah)};

     sub blah{
         my $self = shift;
         return 1;
     }

     [...]

     package Bar;

     sub method_that_bar_provides{
          print qq(Hello World!\n);
     }

     sub _methods($$){
          return qw(method_that_bar_provides);
     }

     [...]

     use Foo;

     $foo = new Foo;
     $foo->load('Bar');
     $foo->blah && $foo->method_that_bar_provides;


=head1 DESCRIPTION

Class::Modular is a superclass for generating modular classes, where
methods can be added into the class from the perspective of the
object, rather than the perspective of the class.

That is, you can create a class which has a set of generic common
functions. Less generic functions can be included or overridden
without modifying the base classes. This allows for code to be more
modular, and reduces code duplication.

This module attempts to fill the middle ground between
L<Class::Mutator> and true classless OOP, like L<Class::Classless>.

=head1 FUNCTIONS

=cut

use strict;
use vars qw($VERSION $DEBUG $REVISION $USE_SAFE);

use Carp;

use Storable qw(dclone); # Used for deep copying objects
use Safe; # Use Safe when we are dealing with coderefs

BEGIN{
     $VERSION = q$0.05$;
     ($REVISION) = q$LastChangedRevision: 45 $ =~ /\$LastChangedRevision:\s+([^\s+])/;
     $DEBUG = 0 unless defined $DEBUG;
     $USE_SAFE = 1 unless defined $USE_SAFE;
}

# This is the class_modular namespace, so we don't muck up the
# subclass(es) by accident.

my $cm = q(__class_modular);

our $AUTOLOAD;


=head2 load

     $cm->load('Subclass');
     # or
     $cm->load('Subclass',$options);

Loads the named Subclass into this object if the named Subclass has
not been loaded.

If debugging is enabled, will warn about loading already loaded
subclasses. Use C<$cm->is_loaded('Subclass')> to avoid these warnings.

=head3 Methods

If the subclass has a C<_methods> function (or at least,
UNIVERSAL::can thinks it does), C<_methods> is called to return a LIST
of methods that the subclass wishes to handle. The L<Class::Modular>
object and the options SCALAR are passed to the _methods function.

If the subclass does not have a C<_methods> function, then the array
C<@{"${subclass}::METHODS"}> is used to determine the methods that the
subclass will handle.

=head3 _init and required submodules

If the subclass has a C<_init> function (or at least, UNIVERSAL::can
thinks it does), C<_init> is called right after the module is
loaded. The L<Class::Modular> object and the options SCALAR are passed
to the _methods function. Typical uses for this call are to load other
required submodules.

As this is the most common thing to do in C<_init>, if a subclass
doesn't have one, then the array C<@{"${subclass}::SUB_MODULES"}> is
used to determine the subclass that need to be loaded:

    for my $module (@{"${subclass}::SUB_MODULES"}) {
	 $self->is_loaded($module) || $self->load($module);
    }

=cut

sub load($$;$) {
     my ($self,$subclass,$options) = @_;

     $options ||= {};

     # check to see if the subclass has already been loaded.

     if (not defined $self->{$cm}{_subclasses}{$subclass}){
	  eval {
	       no strict 'refs';
	       # Yeah, I don't care if calling an inherited AUTOLOAD
	       # for a non method is deprecated. Bite me.
	       no warnings 'deprecated';
	       eval "require $subclass" or die $@;
	       # We should read @METHODS and @SUB_MODULES and just do
	       # the right thing if at all possible.
	       my $methods = can($subclass,"_methods");
	       if (defined $methods) {
		    $self->_addmethods($subclass,&$methods($self,$options));
	       }
	       else {
		    $self->_addmethods($subclass,@{"${subclass}::METHODS"})
	       }
	       my $init = can($subclass,"_init");
	       if (defined $init) {
		    &$init($self,$options);
	       }
	       else {
		    for my $module (@{"${subclass}::SUB_MODULES"}) {
			 $self->is_loaded($module) || $self->load($module);
		    }
	       }
	  };
	  die $@ if $@;
	  $self->{$cm}{_subclasses}{$subclass} ||= {};
     }
     else {
	  carp "Not reloading subclass $subclass" if $DEBUG;
     }
}

=head2 is_loaded

     if ($cm->is_loaded('Subclass')) {
           # do something
     }

Tests to see if the named subclass is loaded.

Returns 1 if the subclass has been loaded, 0 otherwise.

=cut

sub is_loaded($$){
     my ($self,$subclass) = @_;

     # An entry will exist in the _subclasses hashref only if 
     return 1 if exists $self->{$cm}{_subclasses}{$subclass}
	  and defined $self->{$cm}{_subclasses}{$subclass};
     return 0;
}

=head2 override

     $obj->override('methodname', $code_ref)

Allows you to override utility functions that are called internally to
provide a different default function.  It's superficially similar to
_addmethods, which is called by load, but it deals with code
references, and requires the method name to be known.

Methods overridden here are _NOT_ overrideable in _addmethods. This
may need to be changed.

=cut

sub override {
     my ($self, $method_name, $function_reference) = @_;

     $self->{$cm}{_methodhash}{$method_name}{reference} = $function_reference;
     $self->{$cm}{_methodhash}{$method_name}{overridden} = 1;
}


=head2 clone

     my $clone  = $obj->clone

Produces a clone of the object with duplicates of all data and/or new
connections as appropriate.

Calls _clone on all loaded subclasses.

Warns if debugging is on for classes which don't have a _clone method.
Dies on other errors.

clone uses L<Safe> to allow L<Storable> to deparse code references
sanely. Set C<$Class::Modular::USE_SAFE = 0> to disable this. [Doing
this may cause errors from Storable about CODE references.]

=cut

sub clone {
     my ($self) = @_;

     my $clone = {};
     bless $clone, ref($self);

     # copy data structures at this level
     if ($self->{$cm}{use_safe}) {
	  my $safe = new Safe;
	  $safe->permit(qw(:default require));
	  local $Storable::Deparse = 1;
	  local $Storable::Eval = sub { $safe->reval($_[0]) };
	  $clone->{$cm}{_methodhash} = dclone($self->{$cm}{_methodhash});
	  $clone->{$cm}{_subclasses} = dclone($self->{$cm}{_subclasses});
     }
     else {
	  $clone->{$cm}{_methodhash} = dclone($self->{$cm}{_methodhash});
	  $clone->{$cm}{_subclasses} = dclone($self->{$cm}{_subclasses});
     }

     foreach my $subclass (keys %{$self->{$cm}{_subclasses}}) {
	  # Find out if the subclass has a clone method.
	  # If it does, call it, die on errors.
	  my $function = UNIVERSAL::can($subclass, '_clone');
	  eval {
	       no strict 'refs';
	       # No, I could care less that AUTOLOAD is
	       # deprecated. Eat me.
	       no warnings 'deprecated';
	       &{"${subclass}::_clone"}($self,$clone);
	  };
	  if ($@) {
	       # Die unless we've hit an undefined subroutine.
	       if ($@ !~ /^Undefined function ${subclass}::_clone at [^\n]*$/){
		    die "Failed while trying to clone: $@";
	       }
	       else {
		    carp "No _clone method defined for $subclass" if $DEBUG;
	       }
	  }
     }
}


=head2 can

     $obj->can('METHOD');
     Class::Modular->can('METHOD');

Replaces UNIVERSAL's can method so that handled methods are reported
correctly. Calls UNIVERSAL::can in the places where we don't know
anything it doesn't.

Returns a coderef to the method if the method is supported, undef
otherwise.

=cut

sub can{
     my ($self,$method,$vars) = @_;

     croak "Usage: can(object-ref, method, [vars]);\n" if not defined $method;

     if (ref $self and exists $self->{$cm}{_methodhash}->{$method}) {
	  # If the method is defined, return a reference to the
	  # method.
	  return $self->{$cm}{_methodhash}{$method}{reference};
     }
     else {
	  # Otherwise, let UNIVERSAL::can deal with the method
	  # appropriately.
	  return UNIVERSAL::can($self,$method);
     }
}

=head2 isa

     $obj->isa('TYPE');
     Class::Modular->isa('TYPE');

Replaces UNIVERSAL's isa method with one that knows which modules have
been loaded into this object. Calls C<is_loaded> with the type passed,
then calls UNIVERSAL::isa if the type isn't loaded.

=cut

sub isa{
     my ($self,$type) = @_;

     croak "Usage: isa(object-ref, type);\n" if not defined $type;

     return $self->is_loaded($type) || UNIVERSAL::isa($self,$type);
}



=head2 handledby

     $obj->handledby('methodname');
     $obj->handledby('Class::Method::methodname');

Returns the subclass that handles the method methodname.

=cut

sub handledby{
     my ($self,$method_name) = @_;

     $method_name =~ s/.*\://;

     if (exists $self->{$cm}{_methodhash}{$method_name}) {
	  return $self->{$cm}{_methodhash}{$method_name}{subclass};
     }
     return undef;
}


=head2 new

     $obj = Foo::Bar->new(qw(baz quux));

Creates a new Foo::Bar object

Aditional arguments can be passed to this creator, and they are stored
in $self->{creation_args} (and $self->{$cm}{creation_args} by
_init.

This new function creates an object of Class::Modular, and calls the
C<$self->load(Foo::Bar)>, which will typically do what you want.

If you override this method in your subclasses, you will not be able
to use override to override methods defined within those
subclasses. This may or may not be a feature. You must also call
C<$self->SUPER::_init(@_)> if you override new.

=cut

sub new {
     my ($class,@args) = @_;

     # We shouldn't be called $me->new, but just in case
     $class = ref($class) || $class;

     my $self = {};

     # But why, Don, are you being evil and not using the two argument
     # bless properly?

     # My child, we always want to go to Class::Modular first,
     # otherwise we will be unable to override methods in subclasses.

     # But doesn't this mean that subclasses won't be able to override
     # us?

     # Only if they don't also override new!

     bless $self, 'Class::Modular';

     $self->_init(@args);

     # Now we call our subclass's load routine so that our evil deeds
     # are masked

     $self->load($class);

     return $self;
}


=head1 FUNCTIONS YOU PROBABLY DON'T CARE ABOUT

=head2 DESTROY

     undef $foo;

Calls all subclass _destroy methods.

Subclasses need only implement a _destroy method if they have
references that need to be uncircularized, or things that should be
disconnected or closed.

=cut

sub DESTROY{
     my $self = shift;
     foreach my $subclass (keys %{$self->{$cm}{_subclasses}}) {
	  # use eval to try and call the subclasses _destroy method.
	  # Ignore no such function errors, but trap other types of
	  # errors.
	  eval {
	       no strict 'refs';
	       # Shove off, deprecated AUTOLOAD warning!
	       no warnings 'deprecated';
	       &{"${subclass}::_destroy"}($self);
	  };
	  if ($@) {
	       if ($@ !~ /^Undefined (function|subroutine) \&?${subclass}::_destroy (|called )at [^\n]*$/){
		    die "Failed while trying to destroy: $@";
	       }
	       else {
		    carp "No _destroy method defined for $subclass" if $DEBUG;
	       }
	  }
     }
}


=head2 AUTOLOAD

The AUTOLOAD function is responsible for calling child methods which
have been installed into the current Class::Modular handle.

Subclasses that have a new function as well as an AUTOLOAD function
must call Class::Modular::AUTOLOAD and set $Class::Modular::AUTOLOAD

     $Class::Modular::AUTOLOAD = $AUTOLOAD;
     goto &Class::Modular::AUTOLOAD;

Failure to do the above will break Class::Modular utterly.

=cut

sub AUTOLOAD{
     my $method = $AUTOLOAD;

     $method =~ s/.*\://;

     my ($self) = @_;

     if (not ref($self)) {
	 carp "Not a reference in AUTOLOAD.";
	 return;
     }

     if (exists $self->{$cm}{_methodhash}{$method} and
	 defined $self->{$cm}{_methodhash}{$method}{reference}) {
	  {
	      my $method = \&{$self->{$cm}{_methodhash}{$method}{reference}};
	      goto &$method;
	  }
     }
     else {
	  croak "Undefined function $AUTOLOAD";
     }
}

=head2 _init

     $self->_init(@args);

Stores the arguments used at new so modules that are loaded later can
read them from B<creation_args>

You can also override this method, but if you do so, you should call
Class::Modular::_init($self,@_) if you don't set creation_args.

=cut

sub _init {
     my ($self,@creation_args) = @_;

     my $creation_args = [@_];
     $self->{creation_args} = $creation_args if not exists $self->{creation_args};

     # Make another reference to this, so we can get it if a subclass
     # overwrites it, or if it was already set for some reason
     $self->{$cm}->{creation_args} = $creation_args;
     $self->{$cm}->{use_safe} = $USE_SAFE;
}


=head2 _addmethods

     $self->_addmethods()

Given an array of methods, adds the methods into the _methodhash
calling table.

Methods that have previously been overridden by override are _NOT_
overridden again. This may need to be adjusted in load.

=cut

sub _addmethods($@) {
     my ($self,$subclass,@methods) = @_;

     # stick the method into the table
     # DLA: Make with the munchies!

     foreach my $method (@methods) {
	  if (not $method =~ /^$subclass/) {
	       $method = $subclass.'::'.$method;
	  }
	  my ($method_name) = $method =~ /\:*([^\:]+)\s*$/;
	  if (exists $self->{$cm}{_methodhash}{$method_name}) {
	       if ($self->{$cm}{_methodhash}{$method_name}{overridden}) {
		    carp "Not overriding already overriden method $method_name\n" if $DEBUG;
		    next;
	       }
	       carp "Overriding $method_name $self->{$cm}{_methodhash}{$method_name}{reference} with $method\n";
	  }
	  $self->{$cm}{_methodhash}{$method_name}{reference} = $method;
	  $self->{$cm}{_methodhash}{$method_name}{subclass} = $subclass;
     }

}


1;


__END__

=head1 BUGS

Because this module works through AUTOLOAD, utilities that use
can($object) instead of $object->can() will fail to see routines that
are actually there. Params::Validate, an excellent module, is
currently one of these offenders.

=head1 COPYRIGHT

This module is part of DA, Don Armstrong's Modules, and is released
under the terms of the GPL version 2, or any later version. See the
file README and COPYING for more information.

Copyright 2003, 2005 by Don Armstrong <don@donarmstrong.com>

=cut




