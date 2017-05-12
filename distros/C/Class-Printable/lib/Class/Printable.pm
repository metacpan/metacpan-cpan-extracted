
package Class::Printable;

use strict;
use warnings;

our $VERSION = '0.02';

## overload operator
use overload q|""| => "toString", fallback => 1;

### methods

# this is the method to be overloaded
sub toString {
	my ($self) = @_;
	return $self->stringValue();
}


# return the unmolested object string
sub stringValue {
	my ($self) = @_;
	return overload::StrVal($self);
}

1;

__END__

=head1 NAME

Class::Printable - A base class for Printable objects

=head1 SYNOPSIS

  package MyObject;
  our @ISA = ('Class::Printable');

=head1 DESCRIPTION

Sometimes it is nice to have your objects return something a bit more complex then C<MyObject=HASH(0x3bac438)> when you C<print> them. This module is a base class for adding that capability to your objects. This is a very simple class which when used as a base does not actually change the normal perl stringification behavior unless you override the classes C<toString> method. Basically, it is there if you need it, and silent otherwise.

=head1 METHODS

=over 4

=item B<toString>

This implementation actually just calls C<stringValue> so that your object will still retain the normal perl stringification behavior. However, if your subclass overrides this method, then the return value of it will be used whenever perl needs to stringify your object.

=item B<stringValue>

This will return the unmolested stringification of your perl object. 

=back

=head1 OPERATORS

=over 4

=item B<"">

This operator, the stringification operator, is implemented with C<toString>.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Class/Printable.pm        100.0    n/a    n/a  100.0  100.0  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0    n/a    n/a  100.0  100.0  100.0  100.0
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

This class is very simple, and is really nothing more than a wrapper around the stringification operator capabilities of L<overload>.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

