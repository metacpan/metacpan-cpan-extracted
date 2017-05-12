
package Class::Interfaces;

use strict;
use warnings;

our $VERSION = '0.04';

sub import {
    my $class = shift;
    my %interfaces = @_;
    foreach my $interface (keys %interfaces) {
        # build the interface
        my (@methods, @subclasses);
        if (ref($interfaces{$interface}) eq 'HASH') {
            my $interface_spec = $interfaces{$interface};
            # if we have an isa
            if (exists ${$interface_spec}{isa}) {
                # if is an array (multiple inheritance)
                if (ref($interface_spec->{isa}) eq 'ARRAY') {
                    @subclasses = @{$interface_spec->{isa}};
                }
                else {
                    # if its another kind of ref, its an error
                    (!ref($interface_spec->{isa}))
                        || $class->_error_handler("Interface ($interface) isa list must be an array reference");
                    # otherwise its just a single item
                    @subclasses = $interface_spec->{isa};
                }
            }
            if (exists ${$interface_spec}{methods}) {
                (ref($interface_spec->{methods}) eq 'ARRAY')
                    || $class->_error_handler("Method list for Interface ($interface) must be an array reference");
                @methods = @{$interface_spec->{methods}};
            }
        }
        elsif (ref($interfaces{$interface}) eq 'ARRAY') {
            @methods = @{$interfaces{$interface}};
        }
        elsif (!defined($interfaces{$interface})) {
            # allow undefined here, this indicates an empty
            # interface, sometimes called a marker interface
            ;
        }
        else {
            $class->_error_handler("Cannot use a " . $interfaces{$interface} . " to build an interface");
        }
        # now create the interfaces
        my $package = $class->_build_interface_package($interface, @subclasses);
        eval $package;
        $class->_error_handler("Could not create Interface ($interface) because", $@) if $@;
        eval {
            my $method_stub = $class->can('_method_stub');    
            no strict 'refs';            
            # without at least this VERSION declaration
            # a Marker interface will not work with
            # 'use base' basically it would complain
            # that the package is empty.      
            # we only assign this if the VERSION is already
            # empty too, so we don't step on any customizations
            # done in subclasses.
            ${"${interface}::"}{VERSION} ||= -1;
            # now we create all our methods :)
            foreach my $method (@methods) {
                ($method !~ /^(BEGIN|INIT|CHECK|END|DESTORY|AUTOLOAD|import|bootstrap)$/)
                    || $class->_error_handler("Cannot create an interface using reserved perl methods");
                *{"${interface}::${method}"} = $method_stub;
            }
        };
        $class->_error_handler("Could not create sub methods for Interface ($interface) because", $@) if $@;  
    }
}

sub _build_interface_package {
    my ($class, $interface, @subclasses) = @_;
    my $package = "package $interface;";
    $package .= "\@${interface}::ISA = qw(" . (join " " => @subclasses) . ");" if @subclasses;
    return $package;
}

sub _error_handler { 
    my ($class, $message, $sub_exception) = @_;
    die "$message : $sub_exception" if $sub_exception;
    die "$message";
}

sub _method_stub { die "Method Not Implemented" }

1;

__END__

=head1 NAME

Class::Interfaces - A module for defining interface classes inline

=head1 SYNOPSIS

  # define some simple interfaces
  use Class::Interfaces (
      Serializable => [ 'pack', 'unpack' ],
      Printable    => [ 'toString' ],
      Iterable     => [ 'iterator' ],
      Iterator     => [ 'hasNext', 'next' ]
      );
    
  # or some more complex ones ...
        
  # interface can also inherit from 
  # other interfaces using this form     
  use Class::Interfaces (
      BiDirectionalIterator => { 
          isa     => 'Iterator', 
          methods => [ 'hasPrev', 'prev' ] 
          },
      ResetableIterator => { 
          isa     => 'Iterator', 
          methods => [ 'reset' ] 
          },
      # we even support multiple inheritance
      ResetableBiDirectionalIterator => { 
          isa => [ 'ResetableIterator', 'BiDirectionalIterator' ]
          }
      );
      
  # it is also possible to create an 
  # empty interface, sometimes called 
  # a marker interface
  use Class::Interfaces (
      JustAMarker => undef
      );

=head1 DESCRIPTION

This module provides a simple means to define abstract class interfaces, which can be used to program using the concepts of interface polymorphism.

=head2 Interface Polymorphism

Interface polymorphism is a very powerful concept in object oriented programming. The concept is that if a class I<implements> a given interface it is expected to follow the guidelines set down by that interface. This in essence is a contract between the implementing class an all other classes, which says that it will provide correct implementations of the interface's abstract methods. Through this, it then becomes possible to treat an instance of an implementing class according to the interface and not need to know much of anything about the actual class itself. This can lead to highly generic code which is able to work with a wide range of virtually arbitrary classes just by using the methods of the certain interface which the class implements. Here is an example, using the interfaces from the L<SYNOPSIS> section:
  
  eval {
      my $list = get_list();
      $list->isa('Iterable') || die "Unable to process $list : is not an Iterable object";
      my $iterator = $list->iterator();
      $iterator->isa('Iterator') || die "Unrecognized iterator type : $iterator";
      while ($iterator->hasNext()) {
          my $current = $iterator->next();
          if ($current->isa('Serializable')) {
              store_into_database($current->pack());
          }
          elsif ($current->isa('Printable')) {
              store_into_database($current->toString());
          }
          else {
              die "Unable to store $current into database : unrecognized object type";
          }
      }
  };
  if ($@) {
      # ... do something with the exception
  }  
  
Now, this may seem like there is a lot of manual type checking, branching and error handling, this is due to perl's object type system. Some say that perl is a strongly typed langugage because a SCALAR cannot be converted (cast) as an ARRAY, and conversions to a HASH can only be done in limited circumstances. Perl enforces these rules at both compile and run time. However, this strong typing breaks down when it comes to perl's object system. If we could enforce object types in the same way we can enforce SCALAR, ARRAY and HASH types, then the above code would need less manual type checking and therefore less branching and error handling. For instance, below is a java-esque example of the same code, showing how type checking would simplify things.
  
  Iterable list = get_list();
  Iterator iterator = list.iterator();
  while (iterator.hasNext()) {
      try {
          store_into_database(iterator.next());
      }
      catch (Exception e) { 
          // ... do something with the exception
      }
  }

  void store_into_database (Serializable current) { ... }
  void store_into_database (Printable current) { ... }

While the java-esque example is much shorter, it is really doing the same thing, just all the type checking and error handling is performed by the language itself. But the power of the concept of interface polymorphism is not lost.

=head2 Subclassing Class::Interfaces

For the most part, you will never need to subclass Class::Interfaces since it's default behavior will most likley be sufficient for most class stub generating needs. However, it is now possible (as of 0.02) to subclass Class::Interfaces and customize some of it's behavior. Below in the L<CLASS METHODS> section, you will find a list of methods which you can override in your Class::Interfaces subclass and therefore customize how your interfaces are built.

=head1 INTERFACE

Class::Interfaces is interacted with through the C<use> interface. It expects a hash of interface descriptors in the following formats.

=over 4

=item E<lt>I<interface name>E<gt> =E<gt> [ E<lt>list of method namesE<gt> ]

An interface can be simply described as either an ARRAY reference containing method labels as strings, or as C<undef> for empty (marker) interfaces. 

=item E<lt>I<interface name>E<gt> =E<gt> { E<lt>interface descriptionE<gt> }

Another option is to use the HASH reference, which can support the following key value pair formats.

=over 4

=item isa =E<gt> E<lt>super interfaceE<gt>

An interface can inherit from another interface by assigning an interface name (as a string) as the value of the C<isa> key.

=item isa =E<gt> [ E<lt>list of super interfacesE<gt> ]

Or an interface can inherit from multiple interfaces by assigning an ARRAY reference of interface names (as strings) as the value of the C<isa> key.

=item methods =E<gt> [ E<lt>list of method namesE<gt> ]

An interface can define it's method labels as an ARRAY reference containing string as the value of the C<methods> key. 

=back

Obviously only one form of the C<isa> key can be used at a time (as the second would cancel first out), but you can use any other combination of C<isa> and C<methods> with this format.

=back

=head1 CLASS METHODS

The following methods are class methods, which if you like, can be overriden by a subclass of Class::Interfaces. This can be used to customize the building of interfaces for your specific needs.

=over

=item B<_build_interface_package ($class, $interface, @subclasses)>

This method is used to construct a the interface package itself, it just creates and returns a string which Class::Interfaces will then C<eval> into being. 

This method can be customized to do any number of things, such as; add a specified namespace prefix onto the C<$interface> name, add additional classes into the C<@subclasses> list, basically preprocess any of the arguments in any number of ways. 

=item B<_error_handler ($class, $message, $sub_exception)>

All errors which might happen during class generation are sent through this routine. The main use of this is if your application is excepting object-based exceptions and not just string-based exceptions, you can customize this to do that for you.

=item B<_method_stub ($class)>

When a method is created in the interface, it is given a default implementation (or stub). This usually will die with the string "Method Not Implemented", however, this may not always be what you want it to do. 

This can be used much like C<_error_handler> in that you can make it throw an object-based exception if that is what you application expects. But it can also be used to log missing methods, or to not do anything and just allow things to fail silently too. It is all dependent upon your needs.

=back

=head1 TO DO

The documentation needs some work. 

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Class/Interfaces.pm           100.0  100.0   50.0  100.0    n/a  100.0   98.9
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                         100.0  100.0   50.0  100.0    n/a  100.0   98.9
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

=over 4

=item L<Object::Interface>

=item L<interface>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks for Matthew Simon Cavalletto for pointing out a problem with a reg-exp and for suggestions on the documentation.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

