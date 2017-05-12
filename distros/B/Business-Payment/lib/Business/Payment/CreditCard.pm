package Business::Payment::CreditCard;
use Moose;

use Business::Payment::Types;

extends 'Business::Payment::Charge';

with 'MooseX::Traits';

has '+_trait_namespace' => (
    default => 'Business::Payment::CreditCard'
);

has 'csc' => (
    is => 'rw',
    isa => 'Num'
);

has 'expiration' => (
    is       => 'rw',
    isa      => 'DateTime',
    coerce   => 1,
    required => 1
);

has 'number' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1
);

sub expiration_formatted {
    shift->expiration->strftime(shift);
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Business::Payment::CreditCard - Credit Card object

=head1 SYNOPSIS

    use Business::Payment::CreditCard;

    my $bp = Business::Payment::CreditCard->new(
        number => '4111111111111111'
    );

=head1 DESCRIPTION

Business::Payment::CreditCard provides a model for passing Credit Card
information to a Charge.

=head1 ATTRIBUTES

=head2 csc

Set/Get the Card Security Code for this Credit Card.  This is also
referred to as the CVV, CVV2, CVVC, CVC, V-Code or CCV.

http://en.wikipedia.org/wiki/Card_Verification_Value

=head2 expiration

Set/Get the expiration for this Credit Card.  Expects a DateTime object,
but can coerce a String.

=head2 number

Set/Get the credit card number.

=head1 METHODS

=head2 expiration_formatted ($format)

Returns a stringified version of the expiration date using the supplied
format.  (See DateTime's strftime)

=head1 AUTHOR

Jay Shirley, C<< <jshirley@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.