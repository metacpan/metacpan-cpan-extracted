package Business::Payment::ClearingHouse;
use Moose;

use Data::UUID;

our $VERSION = '0.01';

has 'charges' => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef[Business::Payment::ClearingHouse::Charge]',
    default => sub { {} },
    handles => {
        'delete_charge' => 'delete',
        'get_charge' => 'get',
        'set_charge' => 'set'
    }
);

has 'number_verifier' => (
    traits => [ 'Code' ],
    is => 'ro',
    isa => 'CodeRef',
    default => sub { sub { return 1 } },
    handles => {
        verify_number => 'execute'
    }
);

has 'states' => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef[Str]',
    default => sub { {} },
    handles => {
        'delete_state' => 'delete',
        'get_state' => 'get',
        'set_state' => 'set'
    }
);

has 'uuid' => (
    is => 'ro',
    lazy_build => 1
);

sub _build_uuid {
    my ($self) = @_;

    return Data::UUID->new;
}

sub auth {
    my ($self, $charge) = @_;

    # unless($self->verify_number($charge->number)) {
    #     die "Invalid number\n";
    # }

    my $uuid = $self->uuid->create_str;

    $self->set_charge($uuid, $charge);
    $self->set_state($uuid, 'auth');

    return $uuid;
}

sub credit {
    my ($self, $charge) = @_;

    my $uuid = $self->uuid->create_str;

    $self->set_state($uuid, 'credit');
    $self->set_charge($uuid, $charge);
}

sub info {
    my ($self, $uuid) = @_;

    return $self->get_charge($uuid);
}

sub postauth {
    my ($self, $uuid) = @_;

    my $charge = $self->get_charge($uuid);
    unless(defined($charge)) {
        die "Unknown Charge\n";
    }

    my $status = $self->get_state($uuid);
    unless(defined($status) && ($status eq 'preauth')) {
        die "Must preauth before postauthing\n";
    }

    $self->set_state($uuid, 'postauth');

    return 1;
}

sub preauth {
    my ($self, $charge) = @_;

    # unless($self->verify_number($charge->number)) {
    #     die "Invalid number\n";
    # }

    my $uuid = $self->uuid->create_str;

    $self->set_charge($uuid, $charge);
    $self->set_state($uuid, 'preauth');

    return $uuid;
}

sub settle {
    my ($self) = @_;

    my $total = 0;

    foreach my $uuid (keys %{ $self->states }) {
        my $state = $self->get_state($uuid);
        my $charge = $self->get_charge($uuid);

        if($state eq 'preauth') {
            # Skip these, as they are in flight
            next;
        } elsif($state eq 'auth' || $state eq 'postauth') {
            $total += $charge->total;
        } elsif($state eq 'credit') {
            $total -= $charge->total;
        }

        # Since we got here, we can just delete it now.
        $self->delete_state($uuid);
        $self->delete_charge($uuid);
    }

    return $total;
}

sub void {
    my ($self, $uuid) = @_;

    my $charge = $self->get_charge($uuid);

    if(defined($charge)) {
        $self->delete_charge($uuid);
        $self->delete_state($uuid);
        return 1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

=head1 NAME

Business::Payment::ClearingHouse - ClearingHouse for Business::Payment

=head1 SYNOPSIS

    use Business::Payment::ClearingHouse;

    my $house = Business::Payment::ClearingHouse->new();

    # Create a charge
    my $charge = Business::Payment::ClearingHouse::Charge->new(
        subtotal => 100,
        tax      => 10
    );
    # Authorizate it and get the uuid
    my $uuid = $house->auth($charge);

    # Settle!
    my $total = $house->settle;

=head1 DESCRIPTION

Business::Payment::ClearingHouse provides an API that emulates a payment
processor like the ones used with credit cards.  The operations it provides
are inspired by those present with a credit card processor: preauth (reserve),
postauth (consume the reserved funds), auth (immediately charge), credit
(refund) and void (remove a charge).

This module is intended to provide a testbed for features of
L<Business::Payment> and to provide a testing processor for use in development
environments.  The C<settle> method allows a developer to examine the net
results of a series of transactions.

B<Notice>: This module is in development.  The API will likely change.

=head1 ATTRIBUTES

=head2 charges

Hashref of charges.  Keys are the UUIDs and values are the charge objects.

=head2 states

Hashref of charge states. Keys are the UUIDs and the values are the strings
that represent state.  One of preauth, postauth, auth or credit.

=head2 uuid

The UUID generator used by this object, a lazily insantiated Data::UUID
object.

=head1 METHODS

=head2 auth ($charge)

Performs an immediate auth for the supplied charge.

=head2 credit ($charge)

Performs a credit for the supplied charge.

=head2 info ($uuid)

Returns the charge associated with the supplied UUID.

=head2 postauth ($uuid)

Performs a post-authorization for the charge tied to the supplied UUID.  This
is the second operation after a C<preauth>.

=head2 preauth ($charge)

Performs a pre-authorization for the supplied charge.  This should be followed
by a C<postauth>.

=head2 settle

Totals up and removes all pending transactions.  Returns the total (sum of all
auth and postauth, less any credits).  Any remaining preauth transactions
are left in the clearinghouse to be postauthed later.

=head2 void ($uuid)

Voids the charge with the supplied UUID. Removes any information about the
charge from the clearinghouse.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
