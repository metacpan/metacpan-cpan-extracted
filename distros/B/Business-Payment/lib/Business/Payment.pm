package Business::Payment;
use Moose;

our $VERSION = '0.02';

use Business::Payment::Charge;

has processor => (
    is       => 'ro',
    does     => 'Business::Payment::Processor',
    required => 1,
);

sub handle {
    my ($self, $charge) = @_;

    return $self->processor->handle($charge);
}

sub charge {
    my ( $self, %fields ) = @_;

    my $roles = $self->processor->charge_roles;
    return Business::Payment::Charge->new_with_traits(
        traits => $roles,
        %fields
    );
}

sub refund {
    my ( $self, %fields ) = @_;

    my $roles = $self->processor->refund_roles;
    $fields{type} ||= 'CREDIT';
    return Business::Payment::Charge->new_with_traits(
        traits => $roles,
        %fields
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Business::Payment - Payment Processing Library

=head1 SYNOPSIS

    use Business::Payment;

    my $bp = Business::Payment->new(
        processor => Business::Payment::Processor::Test::True->new
    );

    my $charge = Business::Payment::Charge->new(
        amount => 10.00 # Something Math::Currency can parse
    );

    my $result = $bp->handle($charge);
    if($result->success) {
        print "Success!\n";
    } else {
        print "Failed: ".$result->error_code.": ".$result->error_message."\n";
    }

=head1 NOTICE

This module is currently under development and not recommended for production
use. The API is unstable! Contributions and suggestions are welcome.

=head1 DESCRIPTION

Business::Payment is a payment abstraction library, primarily meant to be used
in front of payment processor libraries.  The expected use is for credit cards
but care is taken to assume little and to allow the implementor to choose
what functionality is needed, leaving the door open for other payment processing
needs.

=head1 AUTHOR

Cory G Watson, C<< <gphat@cpan.org> >>
J. Shirley, C<< <jshirley+cpan@gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
