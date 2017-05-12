package TEquality;

use strict;
use warnings;

our $VERSION = '0.31';

use Class::Trait 'base';

our %OVERLOADS = (
    '==' => "equalTo",
    '!=' => "notEqualTo"
);

our @REQUIRES = ("equalTo");

sub notEqualTo {
    my ( $left, $right ) = @_;
    return not $left->equalTo($right);
}

sub isSameTypeAs {
    my ( $left, $right ) = @_;

    # we know the left operand is an object right operand must be an object
    # and either right is derived from the same type as left or left is
    # derived from the same type as right

    return ( ref($right)
          && ( $right->isa( ref($left) ) || $left->isa( ref($right) ) ) );
}

# this method attempts to decide if an object is exactly the same as one
# another. It does this by comparing the Perl built-in string representations
# of a reference and displays the object's memory address.

sub isExactly {
    my ( $self, $candidate ) = @_;

    # $candidate must also be a Comparable object, otherwise there is no way
    # they can be the same.  Along the same veins, we can check very quickly
    # to see if we are dealing with the same objects by testing the values
    # returned by ref(), for if they are not the same, then again, this fails.

    return 0 unless ref($self) eq ref($candidate);

    # from now on this gets a little trickier...  First we need to test if the
    # objects are Printable, since this will prevent us from being able to get
    # a proper string representation of the object's memory address through
    # normal stringification, and so we will need to call its method
    # stringValue (see the Printable interface for more info)

    return ( $self->stringValue() eq $candidate->stringValue() )
      if $self->does("TPrintable");

    # if the object is not Printable, that means that we can use the built in
    # Perl stringification routine then, so we do just that, if these strings
    # match then the memory address will match as well, and we will know we
    # have the exact same object.

    return ( "$self" eq "$candidate" );
}

1;

__END__

=head1 NAME 

TEquality - Trait for adding equality testing to your object

=head1 DESCRIPTION

TEquality adds a number of equality testing features, including type-equality
as well as object instance equality. 

=head1 REQUIRES

=over 4

=item B<equalTo ($left, $right)>

The C<equalTo> method is expected to return either true if its two arguments
are equal (by whatever standards your devise), or false if they are not. 

=back

=head1 OVERLOADS

=over 4

=item B<==>

=item B<!=>

=back

=head1 PROVIDES

=over 4

=item B<notEqualTo ($left, $right)>

This is the inverse of C<equalTo>.

=item B<isSameTypeAs ($left, $right)>

This will determine type equality, meaning it will determine if both
arguements are derived from the same type.

=item B<isExactly ($left, $right)>

This will attempt to discern whether or not the two arguments given are the
same object. It even takes into account the possibility that the objects might
also have utilized the TPrintable trait, and so works around that automatic
stringification.

=back

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com> 

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
