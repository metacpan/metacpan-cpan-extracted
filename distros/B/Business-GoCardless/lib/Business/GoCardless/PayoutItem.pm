package Business::GoCardless::PayoutItem;

=head1 NAME

Business::GoCardless::PayoutItem

=head1 DESCRIPTION

A class for a gocardless payout item, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    amount
    links
    taxes
    type

=cut

has [ qw/
    amount
    links
    taxes
    type
/ ] => (
    is => 'rw',
);

=head1 Links

Shortcut methods to get the IDs of the linked resources

    payment_id
    mandate_id
    refund_id

=cut

sub payment_id { return ( shift->links // {} )->{payment} }
sub mandate_id { return ( shift->links // {} )->{mandate} }
sub refund_id  { return ( shift->links // {} )->{refund} }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
