
package Class::Cloneable;

use strict;
use warnings;

our $VERSION = '0.03';

sub clone {
    my ($self) = @_;
    return Class::Cloneable::Util::clone($self);
}

package Class::Cloneable::Util;

use strict;
use warnings;

use overload ();
use Carp qw(confess);
use Scalar::Util qw(blessed reftype weaken isweak);

our $VERSION = '0.03';

sub clone {
    (UNIVERSAL::isa((caller)[0], 'Class::Cloneable') || 
     UNIVERSAL::isa((caller)[0], 'Class::Cloneable::Util')) 
        || confess "Illegal Operation : This method can only be called by a subclass of Class::Cloneable";        
    my ($to_clone, $cache) = @_;
    (defined($to_clone)) 
        || confess "Insufficient Arguments : Must specify the object to clone";    
    # To start with, non-reference values are
    # not copied, just returned, cache or not
    return $to_clone unless ref($to_clone);
    # now check for an active cache
    unless(defined $cache) {
        # now we check to see what we have,
        # and deconstruct and deep copy the 
        # top-level Class::Cloneable objects
        if (blessed($to_clone) && $to_clone->isa('Class::Cloneable')) {
            # now copy the object's internals and
            # bless the new clone into the right class
            # storing it in the cache case we run 
            # into a circular ref
            return $cache->{$to_clone} = bless(
                cloneRef($to_clone, ($cache = {}), reftype($to_clone)), 
                blessed($to_clone)
            );    
        }
        # if it is not a Class::Cloneable, then 
        # we just proceed as normal
    }
    # if we have it in the cache them return the cached clone
    return $cache->{$to_clone} if exists $cache->{$to_clone};
    # now try it as an object, which will in
    # turn try it as ref if its not an object
    # now store it in case we run into a circular ref
    return $cache->{$to_clone} = cloneObject($to_clone, $cache);    
}

sub cloneObject {
    (UNIVERSAL::isa((caller)[0], 'Class::Cloneable') || 
     UNIVERSAL::isa((caller)[0], 'Class::Cloneable::Util')) 
        || confess "Illegal Operation : This method can only be called by a subclass of Class::Cloneable"; 
    my ($to_clone, $cache) = @_;
    (ref($to_clone) && (ref($cache) && ref($cache) eq 'HASH')) 
        || confess "Insufficient Arguments : Must specify the object to clone and a valid cache";    
    # check to see if we have an Class::Cloneable object,
    # or check to see if its an object, with a clone method    
    if (blessed($to_clone)) {
        # note, we want to be sure to respect any overriding of
        # the clone method with Class::Cloneable objects here
        # otherwise it would be faster to just send it directly
        # to the Class::Cloneable::Util::clone function above
        return $cache->{$to_clone} = ($to_clone->can('clone') ? 
                    $to_clone->clone()
                    : 
                    # or if we have an object, with no clone method, then
                    # we will respect its encapsulation, and not muck with 
                    # its internals. Basically, we assume it does not want
                    # to be cloned                    
                    $to_clone);
    }
    # if all else fails, it is likely a basic ref
    return $cache->{$to_clone} = cloneRef($to_clone, $cache);     
}

sub cloneRef {
    (UNIVERSAL::isa((caller)[0], 'Class::Cloneable') || 
     UNIVERSAL::isa((caller)[0], 'Class::Cloneable::Util')) 
        || confess "Illegal Operation : This method can only be called by a subclass of Class::Cloneable"; 
    my ($to_clone, $cache, $ref_type) = @_;
    (ref($to_clone) && (ref($cache) && ref($cache) eq 'HASH')) 
        || confess "Insufficient Arguments : Must specify the object to clone and a valid cache";        
    $ref_type = ref($to_clone) unless defined $ref_type;
    # check if it is weakened
    my $is_weak;
    $is_weak = 1 if isweak($to_clone);    
    my ($clone, $tied);
    if ($ref_type eq 'HASH') {
        $clone = {};
        tie %{$clone}, ref $tied if $tied = tied(%{$to_clone});
        %{$clone} = map { ref($_) ? clone($_, $cache) : $_ } %{$to_clone};
    } 
    elsif ($ref_type eq 'ARRAY') {
        $clone = [];
        tie @{$clone}, ref $tied if $tied = tied(@{$to_clone});
        @{$clone} = map { ref($_) ? clone($_, $cache) : $_ } @{$to_clone};
    } 
    elsif ($ref_type eq 'REF' or $ref_type eq 'SCALAR') {
        my $var = "";
        $clone = \$var;
        tie ${$clone}, ref $tied if $tied = tied(${$to_clone});
        ${$clone} = clone(${$to_clone}, $cache);
    } 
    else {
        # shallow copy reference to code, glob, regex
        $clone = $to_clone;
    }
    # store it in our cache
    $cache->{$to_clone} = $clone;
    # and weaken it if appropriate
    weaken($clone) if $is_weak;
    # and return the clone
    return $clone;    
}

1;

__END__

=head1 NAME

Class::Cloneable - A base class for Cloneable objects.

=head1 SYNOPSIS

  package MyObject;
  our @ISA = ('Class::Cloneable');

  # calling clone on an instance of MyObject 
  # will give you full deep-cloning functionality

=head1 DESCRIPTION

This module provides a flexible base class for building objects with cloning capabilities. This module does it's best to respect the encapsulation of all other objects, including subclasses of itself. This is intended to be a stricter and more OO-ish option than the more general purpose L<Clone> and L<Clone::PP> modules.

=head1 METHODS

=head2 Public Method

=over 4

=item B<clone>

This provided method will deep copy itself and return the clone, while respecting the encapsulation of any objects contained within itself. 

For the most part, this will just "I<do the right thing>" and can be used as-is. If however, you need a more specialized approach, see the section below for details on how you can override and customize this methods functionality.

=back

=head2 Inner Package

Class::Cloneable::Util is a protected inner package, meaning that it can only be used by Class::Cloneable or it's subclasses. If an attempt is made to use it outside of that context, an exception is thrown. 

This inner package is provided as a means of performing fine grained custom cloning operations for users who choose to or need to override the C<clone> method provided by Class::Cloneable. Here is a basic example:

  package MyMoreComplexObject;
  our @ISA = ('Class::Cloneable');
  
  sub clone {
    my ($self) = @_;
    my $clone = {};
    $clone->{dont_clone_this} = $self->{dont_clone_this};
    $clone->{clone_this} = Class::Cloneable::Util::clone($self->{clone_this});
    return bless $clone, ref($self);
  }

B<NOTE:> Many of the functions provided in this package require a C<$cache> argument, which is a HASH reference that is used internally to keep track of the items already cloned to avoid cloning any circular references more than once. The only function here which does I<not> require a C<$cache> argument is the C<clone> function, which will initialize its own C<$cache> if one is not present.

=over 4

=item B<clone ($to_clone, $cache)>

For most custom cloning, just calling this function will be enough. The argument C<$to_clone> is required, but the C<$cache> argument can be omitted. This is only allowed in this function, all other functions in this package B<require> that the C<$cache> argument is a HASH reference. 

This function will attempt to clone the C<$to_clone> argument following these guidelines:

=over 4

=item I<If C<$to_clone> is a Class::Cloneable derived object B<and> C<$cache> is undefined>

Then it is assumed that you are requested a "root" level cloning and the Class::Cloneable object is deconstructed and its internals are cloned. This results in a deep copy of the object in C<$to_clone>, which will recursively call this C<Class::Cloneable::Util::clone> function for each internal element.

=item I<If C<$to_clone> is a Class::Cloneable derived object B<and> C<$cache> is B<not> undefined>

This is I<not> considered a "root" level cloning so the C<clone> method is called on the C<$to_clone> object. By doing this, we respect the encapsulation of the Class::Cloneable subclass, in case it's C<clone> method has been overridden with custom behavior. 

=item I<If C<$to_clone> is an object with an available C<clone> method>

This will call the C<clone> method found and assume the value returned is a proper clone of the value in C<$to_clone>.

=item I<If C<$to_clone> is an object without an available C<clone> method>

We assume that because there is no C<clone> method available to the object found stored in C<$to_clone>, that the object does not want to be cloned. The idea is that we should respect the encapsulation of the object and not try to copy it's internals without it's permission.

=item I<If C<$to_clone> is a reference>

We will deep copy the reference value in C<$to_clone>, which will result in recursive calls to the C<Class::Cloneable::Util::clone> function for all the internal values found inside C<$to_clone>. This will also properly clone any C<tied> references, being sure to C<tie> the clones as well.

It is important to note that any CODE, RegExp and GLOB references are not copied, only passed through. Short of some really insane perl code, this is pretty much not possible (nor is it really recommended). 

=item I<If C<$to_clone> is not a reference>

We will simply return a copy of the value in C<$to_clone>. 

=back

As I said, this function (C<clone>) is the central function in this inner package. All other functions are called by this function, and unless you have really specific needs will likely never been used by others.

=item B<cloneObject ($to_clone, $cache)>

This function will assume that C<$to_clone> is an object, and try to follow the guidelines above where they pertain to objects. However, if C<$to_clone> is not an object, and instead an unblessed reference, this function will pass C<$to_clone> to C<cloneRef> for cloning. 

If C<$to_clone> is not a reference of some kind and C<$cache> is not a HASH reference an exception will be thrown.

=item B<cloneRef ($to_clone, $cache)>

This function will deep copy the reference value in C<$to_clone>, which will result in recursive calls to the C<Class::Cloneable::Util::clone> function for all the values found inside C<$to_clone>. 

If C<$to_clone> is not a reference of some kind and C<$cache> is not a HASH reference an exception will be thrown.

=back

=head1 CAVEATS

This module places no restrictions upon it's subclasses, the user is free to compose their subclasses with just about any type of referent they like; HASH, SCALAR, ARRAY being the most common. However some of the more exotic and rare object construction styles will likely not work as expected (if at all). 

For instance, CODE references and closures are incredibly difficult (if not impossible) to clone correctly, objects created from them are not recommended as they are unlikely to work since we cannot accurately clone them. GLOB and RegExp references are also not cloned, and so will not work correctly. However, there is nothing preventing you from just using Class::Cloneable for the sake of interface polymorphism, and implementing your own C<clone> method with these types of objects.

It is also doubtful that this will work with things like the "Inside-Out" object technique since with this technique object data is not actually stored in the instance, but in a lexical package variable which is keyed by the stringified instance. We can only copy what is found within the actual object instance, and not loosely linked data. 

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CAVEATS

This module makes an attempt to handle C<tied> references, however, the way it approaches them is not ideal and potentially wrong in some cases. So use this with care in such situations.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Class/Cloneable.pm        100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

If you need a general purpose cloning module, this is B<not> the module for you, I recommend either L<Clone> (because it's XS and fast) or L<Clone::PP> (if you don't have access to a C compiler). This module only is meant to be used as a base class for objects which need to have cloning abilities, and can not be used outside of that environment. 

I want to say first, that this module's code was based heavily on the code found in L<Clone::PP> by Matthew Simon Cavalletto (which in turn was initially derived from Ref.pm by David Muir Sharnoff). Using the code in L<Clone::PP> as a basis for the code in this module saved me a lot of time and I owe a debt to that module and it's author for releasing it Open Source so that this was possible.

Now, you may be wondering why I chose to make I<yet another> cloning module? 

My first reason has to do with how these other modules handle objects. Neither L<Clone> and L<Clone::PP> correctly respect object encapsulation. My personal feelings is that if an object does not want to be cloned, it should not be allowed to be cloned (for instance, you would never want to copy a Singleton object, as the whole idea behind a Singleton is that there is only one of them). Upon encountering an object, both L<Clone> and L<Clone::PP> will deep copy it, and therefore violate its encapsulation.

To be fair, if we are talking about really I<strict> encapsulation, then Class::Cloneable violates this too, since it can be used to copy a subclass of Class::Cloneable in a way which technically violates its internal encapsulation. However, this is only for the "root" object, and any subsequent Class::Cloneable objects will be cloned using the C<clone> method (and therefore respecting encapsulation). So while it is not perfect, I feel it is a good compromise between requiring all classes to compose their own C<clone> method and allowing arbitrary deep cloning.

The second reason was to provide more flexibility for overriding a C<clone> method in a subclass. The protected inner package of Class::Cloneable::Util can be used to provide a more fine grained approach to the cloning of your object's internals.

=head1 ACKNOWLEDGMENTS

=over 4

=item Thanks for Matthew Simon Cavalletto for writing L<Clone::PP> which this module is based upon.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
