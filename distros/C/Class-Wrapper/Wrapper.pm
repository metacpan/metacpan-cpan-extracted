package Class::Wrapper;

#use 5.008;
use strict;
use warnings;
use Carp;
#use Switch;



our $VERSION = 0.22;
our $AUTOLOAD;

sub new {
  my ($class,$component) = @_;
  croak __PACKAGE__." constructor argument was not an object reference: ".($component || "UNDEF")
    unless ref($component);
    my $self = bless {
        _component => $component
	}, ref($class) || $class;
  return $self;
}

sub AUTOLOAD {
	my ($self,@args) = @_;
	return if $AUTOLOAD =~ /.*DESTROY$/;
	my ($method) = $self->_get_method_name();
	
	# Switch replaced by older foreach construct for compatibility
	# with Perl older than 5.8
	#switch ($method) {
	#    case /^get_(.+)/ {$self->_add_getter();}
	#    case /^set_(.+)/ {$self->_add_setter();}
	#    else {$self->_add_method();}
	#};
	
	foreach ($method) {
	    /^get_(.+)/ && do {$self->_add_getter();last;};
	    /^set_(.+)/ && do {$self->_add_setter();last;};
	    do {$self->_add_method();};
	}
	
	no strict 'refs';
	return $self->$method(@args);
}

sub _add_getter {
    my ($self) = @_;
    my $method = $self->_get_method_name();
    my $objComponent = $self->_get_component();
    my ($property) = $method =~ /^get_(.+)/;
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my ($self) = @_;
        my $result;
        eval {$result = $objComponent->{$property};};
        croak($@) if $@;
        return $result;
    };
}

sub _add_setter {
    my ($self) = @_;
    my $method = $self->_get_method_name();
    my $objComponent = $self->_get_component();
    my ($property) = $method =~ /^set_(.+)/;
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my ($self,$arg) = @_;
        eval{$objComponent->{$property} = $arg};
        croak($@) if $@;
    };
}

sub _add_method {
    my ($self) = @_;
    my $method = $self->_get_method_name();
    my $objComponent = $self->_get_component();
    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my ($self,@args) = @_;
        my @retval;
        my $retval;
        if (wantarray) {
            eval{@retval = $objComponent->$method(@args);};
            croak($@) if $@;
            return @retval;
        } else {
            eval{$retval = $objComponent->$method(@args);};
            croak($@) if $@;
            return $retval;
        }
    };
}

sub _get_method_name {
    my ($method) = $AUTOLOAD =~ /^.*::(.*)$/;
    return $method;
}

sub _get_component {$_[0]->{_component}}


1;
__END__

=head1 NAME

Class::Wrapper - Decorator base class

=head1 SYNOPSIS

  package SomeClass::Wrapper;
  use base qw(Class::Wrapper);
  
  # Overriding the default constructor
  # Necessary only if new properties must be added
  sub new {
    my ($class, $component) = @_;
    my $self = $class->SUPER::new($component);
    $self->{some_new_value} = "some default value";
    return $self;
  }
  
  # Modifying a method
  sub some_method {
    my ($self) = @_;
    my $component = $self->_get_component();
    return 2 * $component->some_method();
  }
  
  # A new method
  sub some_new_method {
    my ($self) @_;
    return $self->{some_new_value};
  }
  
  package main;
  
  my $wrapper = SomeClass::Wrapper->new($some_object);
  $wrapper->set_colour("red");# Setting "colour" attribute of $some_object
  my $attribute = $wrapper->get_colour();# Retrieving value of attribute "colour" from $some_object
  $wrapper->method_in_some_object();# Method call passed through to some object
  my $value = $wrapper->some_method();# Call to overriding method in wrapper
  my $other_value = $wrapper->some_new_method();

=head1 ABSTRACT

C<Class::Wrapper> is a base module for decorators. Decorators are used to dynamically
attach and detach responsibilities to an object. This is useful in a variety of situations
when inheritance can't be used, or when inheritance would create too heavy objects.


=head1 DESCRIPTION

The C<Class::Wrapper> constructor takes a single argument: the object it is going to decorate.
Subclasses of C<Class::Wrapper> may take more arguments though.

When a method is called on the C<Class::Wrapper> object, it is executed if it has been declared.
If the method has not been declared, a dispatch method is automatically created that passes
the method call through to the underlying object.

As far as method calls go, the C<Class::Wrapper> object behaves exactly like the underlying
object. However, direct access to attributes does not work, because C<$wrapper-<gt>{attribute}>
would access C<attribute> in the wrapper class, not in the underlying object. To handle this
problem, C<Class::Wrapper> autogenerates accessor (get_attributename/set_attributename) methods
to access properties of the underlying object.

=head2 Making a Decorator Inherit the Component

In the original decorator pattern, a component and its decorators inherit the same abstract superclass.
The advantage of doing this is that the decorators will then pass type checks using the isa() method.

It is possible to do this by having the decorator inherit B<both> from C<Class::Wrapper> and from the
abstract component superclass (or directly from a concrete component, if there is no abstract superclass).

When the decorator inherits from the component, no dispatch methods will be autogenerated. Because
of this, it is necessary to write explicit dispatch methods in the decorator for all methods in the
component interface. A basic dispatch method looks like this:

 sub some_method {
   my ($self, @args) = @_;
   return $self->_get_component(@args);
}



=head1 Public Methods

=over

=item * new

 my $wrapper = Class::Wrapper->new($component);

The constructor takes the underlying component object as an argument and returns the decorator
object.

=back

=head1 Private Methods

=over 4

=item * _get_component

 my $component = $self->_get_component();

The C<_get_component> method returns the component object the decorator wraps.
It can be used by methods in C<Class::Wrapper> subclasses.

=back

=head1 BUGS

None known.

=head1 SEE ALSO

None.

=head1 AUTHOR

Henrik Martensson, E<lt>henrik.martensson@aerotechtelub.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Henrik Martensson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
