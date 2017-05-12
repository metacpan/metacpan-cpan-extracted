
package Class::Comparable;

use strict;
use warnings;

our $VERSION = '0.02';

# NOTE:
# magnitude (<, <=, >=, >) is not the same as equality (==, !=)
# there may come a time when it makes sense to implement 
# object equality seperately from object magnitude, so we 
# define equals and notEquals methods and operators seperately,
# which will by default "do the right thing", but allow the 
# flexibility which may be needed down the road

use overload (
    '=='     => "equals",
    '!='     => "notEquals",
    '<=>'    => "_compare",
    fallback => 1
    );

# we do not supply a default here since very rarely 
# would a default be appropriate. So unless
# this is overridden, an exception is thrown.
sub compare { die "Method Not Implemented : no comparison method specified" }

sub _compare {
	my ($left, $right, $reversed) = @_;
    my $r = $left->compare($right);
    # if we are not reversed, then we 
    # can return the unaltered result
    return $r if not $reversed;
    # however, if we *are* reversed, and
    # the result is 0, we can return the
    # unaltered 0 as well. 
    return $r if $r == 0;
    # now if we *are* reveresed, and we
    # are not zero, then we need to negate 
    # our value, which essentially reverses
    # it so 1 becomes -1 and -1 becomes 1 
    return -$r;
}

# equals is implemented in terms of compare
sub equals {
	my ($left, $right) = @_;
	return ($left->compare($right) == 0);
}

# notEquals is implemented in terms of equals
sub notEquals {
	my ($left, $right) = @_;
	return !$left->equals($right);
}

# isBetween is implemented in terms of compare
sub isBetween {
	my ($self, $left, $right) = @_;
    # greater than or equal to the left value
    # and less than or equal to the right value
    return (($self->compare($left) >= 0) && ($self->compare($right) <= 0));    
}

# this method attempts to decide if an object
# is exactly the same as one another. It does
# this by comparing the Perl built-in string 
# representations of a reference and displays
# the object's memory address. 
sub isExactly {
	my ($left, $right) = @_;
    # if nothing is passed, then it cannot be 
    # the same thing, we choose to return false
    # here rather than die so it works when a
    # null pointer is passed.
	return 0 unless defined($right);
	# we check to see if we are dealing with the same 
	# types objects by calling ref, which will return
	# the top level class of the object. If they do 
	# not share that in common, they are certainly not
	# the same object.
	return 0 unless ref($left) eq ref($right);
	# from now on this gets a little trickier...
	# First we need to test if the objects overloads
	# the stringification operator, in which case
	# we need to extract the string value. We can get
	# away with just checking the overloading on the
	# left argument, since our test above has already
	# told us they are the same class.
	return (overload::StrVal($left) eq overload::StrVal($right)) if overload::Method($left, '""');
	# if the object does not overload the stringification 
	# operator, then that means that we can use the built 
	# in Perl stringification routine then. If these strings 
	# match then the memory address will match as well, and 
	# we will know we have the exact same object.
	return ("$left" eq "$right");
}

1;

__END__

=head1 NAME

Class::Comparable - A base class for comparable objects

=head1 SYNOPSIS
  
  # an example subclass 
  
  package Currency::USD;
  
  use base 'Class::Comparable';
  
  sub new { 
    my $class = shift;
    bless { value => shift }, $class;
  }
  
  sub value { (shift)->{value} }
  
  sub compare {
    my ($left, $right) = @_;
    # if we are comparing against another
    # currency object, then compare values
    if (ref($right) && $right->isa('Currency::USD')) {
        return $left->value <=> $right->value;
    }
    # otherwise assume we are comparing 
    # against a numeric value of some kind
    else {
        return $left->value <=> $right;
    }
  }
  
  # an example usage of Class::Comparable object
  
  my $buck_fifty = Currency::USD->new(1.50);
  my $dollar_n_half = Currenty::USD->new(1.50);
  
  ($buck_fifty == $dollar_n_half) # these are equal
  (1.75 > $buck_fifty) # 1.75 is more than a buck fifty      
  
  my $two_bits = Currency::USD->new(0.25);
  
  ($two_bits < $dollar_n_half) # 2 bits is less than a dollar and a half
  ($two_bits == 0.25) # two bits is equal to 25 cents
  
=head1 DESCRIPTION

This module provides two things. First, it provides a base set of methods and overloaded operators for implementing objects which can be compared for equality (C<==> & C<!=>) and magnitude (C<E<lt>>, C<E<lt>=>, C<E<lt>=E<gt>>, C<=E<gt>> & C<E<gt>>). Second, it serves as a marker interface for objects which can be compared much like Java's Comparable interface.   

=head1 METHODS

=over 4

=item B<compare ($compare_to)>

This method is abstract, and will throw an exception unless it is properly overridden by the class which implements Class::Comparable. This method is expected to return 1 if the invocant is greater than C<$compare_to>, 0 if they are equal to one another and -1 if the invocant is less than C<$compare_to>.

B<NOTE:> This method used to have a second argument (C<$is_reversed>) which handled the odd cases where comparison arguments are reversed. This is now handled automatically, so you can simply compare your objects values in the order they are passed to C<compare>, and this class will handle the details. 

=item B<equals ($compare_to)>

Returns true (C<1>) if the invocant is equal to the C<$compare_to> argument (as determined by C<compare>) and return false (C<0>) otherwise.

=item B<notEquals ($compare_to)>

Returns true (C<1>) if the invocant is not equal to the C<$compare_to> argument (as determined by C<equals>) and return false (C<0>) otherwise.

=item B<isBetween ($left, $right)>

Returns true (C<1>) if the invocant is greater than or equal to C<$left> and less than or equal to C<$right> (as determined by C<compare>) and return false (C<0>) otherwise. This method does not enforce the fact that C<$left> should be less than C<$right> so that it can allow for C<compare> to accept non-standard values. 

=item B<isExactly ($compare_to)>

Returns true (C<1>) if the invocant is exactly the same instance as C<$compare_to> and return false (C<0>) otherwise. This method will correctly handle objects who overload the C<""> (stringification) operator.

=back

=head1 OPERATORS

=over 4

=item B<==>

This operator is implemented by the C<equals> method.

=item B<!=>

This operator is implemented by the C<notEquals> method.

=item B<E<lt>=E<gt>>

This operator is implemented by the C<compare> method. It should be noted that perl will auto-generate the means to handle the E<lt>, E<lt>=, E<gt>= and E<gt> operators as well (see the L<overload> docs for more information about auto-generation).

=back

=head1 IMPORTANT NOTE

The C<compare> method now works correctly (and automatically) even if the values being compared are reversed. This usually only happens when an object is compared to another non-object (or another object which doesn't overload the C<E<lt>=E<gt>> operator). For instance, if the object is the left operand, like this:

  ($obj < 5) # the $obj is less than 5
  
then the arguments to the C<compare> routine will be in the correct order. However if the object is the right operand, like this:

  (5 > $obj) # 5 is greater than $obj
  
then the arguments to the C<compare> routine will be in the wrong order, meaning that our first argument is our right operand, and our second argument is our left operand. We take care of the details of reversing the output to make sure that the comparison returns the correct value. 

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Class/Comparable.pm       100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0  100.0  100.0  100.0  100.0  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

There are a number of comparison modules out there (L<http://search.cpan.org/search?query=Compare&mode=all>), many of which can be used in conjunction with this module to help implement the C<compare> method for your class. 

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

