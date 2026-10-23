package Business::GoCardless::CustomerNotification;

=head1 NAME

Business::GoCardless::CustomerNotification

=head1 DESCRIPTION

A class for a gocardless customer notification, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    action_taken
    action_taken_at
    action_taken_by
    id
    links
    type

=cut

has [ qw/
    action_taken
    action_taken_at
    action_taken_by
    id
    links
    type
/ ] => (
    is => 'rw',
);

=head1 Operations on a customer notification

=head2 handle

Handle the notification, meaning you have sent it and GoCardless will not:

    $Notification->handle;

=cut

sub handle { shift->_action( 'handle',@_ ); }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
