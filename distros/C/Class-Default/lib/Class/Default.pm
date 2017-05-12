package Class::Default;

# The Class::Default package allows a class that inherits from
# it to act as both an instantiatable and static class.

# See POD for more details.

use 5.005;
use strict;
use Carp ();

# Define globals
use vars qw{$VERSION %DEFAULT};
BEGIN { 
	$VERSION = '1.51';

	# Create the default object storage.
	%DEFAULT = ();
}

# Get the default object if we are passed the class name.
sub _self { 
	my $either = shift;
	ref($either) ? $either 
	: $DEFAULT{$either} 
		|| ($DEFAULT{$either} = $either->_create_default_object)
		|| Carp::croak "Error while creating default object";
}

# Suplimentary method to reliably get ONLY the class
sub _class { ref $_[0] or $_[0] }

# Retrieve the default object for a class, either from
# the cache, or create it new.
sub _get_default {
	my $class = shift; 
	$DEFAULT{$class}
		|| ($DEFAULT{$class} = $class->_create_default_object)
		|| Carp::croak "Error while creating default object";
}

# Creates the default object. 
# Used to provide options to a constructor to create the default object.
sub _create_default_object {
	my $class = shift;

	### When you copy this to overload it, you should add
	### arguments to the constructor call as needed.

	# Create the new object.
	my $self = $class->new;

	### Make any modifications to the default object here

	$self;
}

1;

__END__

=pod

=head1 NAME

Class::Default - Static calls apply to a default instantiation

=head1 SYNOPSIS

  # Create the defaulted class
  package Foo::Base;
  
  use base 'Class::Default';
  
  sub new { bless {}, $_[0] }
  
  sub show {
      my $self = shift->_self;  
      "$self";
  }
  
  # Do something to the default object
  
  package main;
  
  print Foo::Bar->show;
  
  # Prints 'Foo::Bar=HASH(0x80d22f8)'

=head1 DESCRIPTION

Class::Default provides a mechanism to allow your class to take static method
calls and apply it to a default instantiation of an object. It provides a
flexibility to an API that allows it to be used more confortably in
different situations.

A good example of this technique in use is CGI.pm. When you use a static
method, like C<CGI->header>, your call is being applied to a default
instantiation of a CGI object.

This technique appears to be especially usefull when writing modules that you
want to be used in either a single use or a persistant environment. In a CGI
like environment, you want the simplicity of a static interface. You can
call C<Class->method> directly, without having to pass an instantiation 
around constantly.

=head1 USING THE MODULES

Class::Default provides a couple of levels of control. They start with simple
enabling the method to apply to the default instantation, and move on to 
providing some level of control over the creation of the default object.

=head2 Inheriting from Class::Default

To start, you will need to inherit from Class::Default. You do this in the
normal manner, using something like C<use base 'Class::Default'>, or setting
the @ISA value directly. C<Class::Default> does not have a default
constructor or any public methods, so you should be able to use it a
multiple inheritance situation without any implications.

=head2 Making method work

To make your class work with Class::Default you need to make a small 
adjustment to each method that you would like to be able to access the 
default object.

A typical method will look something like the following

  sub foobar {
      my $self = shift;
      
      # Do whatever the method does
  }

To make the method work with Class::Default, you should change it to 
the following

  sub foobar {
      my $self = shift->_self;
      
      # Do whatever the method does
  }

This change is very low impact, easy to use, and will not make any other
differences to the way your code works. 

=head2 Control over the default object

When needed, Class::Default will make a new instantation of your class
and cache it to be used whenever a static call is made. It does this in
the simplest way possible, by calling C<Class->new()> with no arguments.

This is fine if you have a very pure class that can handle creating a
new object without any arguments, but many classes expect some sort of
argument to the the constructor, and indeed that the constructor that
should be used it the C<new> method.

Enter the C<_create_default_object> method. By overloading the 
C<_create_default_object> method in your class, you can custom create the
default object. This will used to create the default object on demand, the
first time a method is called. For example, the following class demonstrate 
the use of C<_create_default_object> to set some values in the default 
object.

  package Slashdot::User;
  
  use base 'Class::Default';
  
  # Constructor
  sub new {
  	my $class = shift;
  	my $name = shift;
  	
  	my $self = {
  		name => $name,
  		favourite_color => '',
  	};
  	
  	return bless $self, $class;
  }
  
  # Default constructor
  sub _create_default_object {
  	my $class = shift;
  	
  	my $self = $class->new( 'Anonymous Coward' );
  	$self->{favourite_color} = 'Orange';
  	
  	return $self;
  }
  
  sub name {
  	$_[0]->_self->{name};
  }
  
  sub favourite_color {
  	$_[0]->_self->{favourite_color};
  }

That provides a statically accessible default object that could be used as in
the following manner.

  print "The default slashdot user is " . Slashdot::User->name
      . " and they like the colour " . Slashdot::User->favourite_color;

Remember that the default object is persistant, so changes made to the
statically accessible object can be recovered later.

=head2 Getting access to the default object

There are a few ways to do this, but the easiest way is to simple do
the following

  my $default = Slashdot::User->_get_default;

=head1 METHODS

=head2 _self

Used by methods to make the method apply to the default object if called
statically without affecting normal object methods.

=head2 _class

The C<_class> method provides the opposite of the C<_self> method. Instead
of always getting an object, C<_class> will always get the class name, so
a method can be guarenteed to run in a static context. This is not 
essential to the use of a C<Class::Default> module, but is provided as a
convenience.

=head2 _get_default

Used to get the default object directly.

=head2 _create_default_object

To be overloaded by your class to set any properties to the default
object at creation time.

=head1 BUGS

No known bugs, but suggestions are welcome

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Default>

For other issues, contact the author

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/>, L<Class::Singleton>

=head1 COPYRIGHT

Copyright (c) 2002 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
