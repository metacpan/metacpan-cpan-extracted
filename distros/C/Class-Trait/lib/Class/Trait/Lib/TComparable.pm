package TComparable;

use strict;
use warnings;

our $VERSION = '0.31';

## we are a trait
use Class::Trait 'base';

use Class::Trait qw(TEquality);

## overload operator

our %OVERLOADS = ( '<=>' => "compare" );

## requires methods

our @REQUIRES = qw(compare);

### methods

# The equals method is there to provide
# specific handler for the '==' operator (and
# to be sure about how '!=' will react, we
# override the autogeneration with the _notEquals
# method).
# This is here so that one can deal with '==' and '!='
# and not the '<', '<=', '<=>', '=>', '>' operators.
# NOTE:
# Our default implementation of equals actually defers
# to the compare method, and the _notEquals method
# actually defers to the value of equals (and returns
# the inverse), so that an object which wants all
# the operators ('<=>' and co.) will be able to use
# the '==' and '!=' operators without an issue.
# If however compare is not defined, a
# MethodNotImplemented exception will be thrown.
# This retains backwards compatability while still
# allowing for specialization.
sub equalTo {
    my ( $left, $right ) = @_;
    return ( $left->compare($right) == 0 ) ? 1 : 0;
}

1;

__END__


=head1 NAME 

TComparable - Trait for adding comparison abilities to your object

=head1 DESCRIPTION

This trait gives your object a wide range of comparison abilities through its
overloading of the E<lt>=E<gt> operator.

=head1 SUB-TRAITS

=over 4

=item B<TEquality>

=back

=head1 REQUIRES

=over 4

=item B<compare ($left, $right)>

This method should return -1 if C<$left> is less than C<$right>, 0 if C<$left>
is equal to C<$right>, and 1 if C<$left> is greater than C<$right>.

=back

=head1 OVERLOADS

=over 4

=item B<E<lt>=E<gt>>

=back

=head1 PROVIDES

=over 4

=item B<equalTo ($left, $right)>

This fufills the requirement of the sub-trait TEquality.

=back

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
