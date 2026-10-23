package Business::GoCardless::MandateImport;

=head1 NAME

Business::GoCardless::MandateImport

=head1 DESCRIPTION

A class for a gocardless mandate import, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    created_at
    id
    links
    scheme
    status

=cut

has [ qw/
    created_at
    id
    links
    scheme
    status
/ ] => (
    is => 'rw',
);

=head1 Operations on a mandate import

=head2 submit

Submit the mandate import, after which no more entries can be added:

    $Import->submit;

=head2 cancel

Cancel the mandate import (if not yet submitted):

    $Import->cancel;

=cut

sub submit { shift->_action( 'submit',@_ ); }
sub cancel { shift->_action( 'cancel',@_ ); }

=head1 Status checks on a mandate import

    created
    submitted
    cancelled
    processing
    processed

    if ( $MandateImport->created ) {
        ...
    }

=cut

sub created    { return ( shift->status // '' ) eq 'created' }
sub submitted  { return ( shift->status // '' ) eq 'submitted' }
sub cancelled  { return ( shift->status // '' ) eq 'cancelled' }
sub processing { return ( shift->status // '' ) eq 'processing' }
sub processed  { return ( shift->status // '' ) eq 'processed' }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
