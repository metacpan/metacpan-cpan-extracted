package Business::GoCardless::Block;

=head1 NAME

Business::GoCardless::Block

=head1 DESCRIPTION

A class for a gocardless block, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    active
    block_type
    created_at
    id
    reason_description
    reason_type
    resource_reference
    updated_at

=cut

has [ qw/
    active
    block_type
    created_at
    id
    reason_description
    reason_type
    resource_reference
    updated_at
/ ] => (
    is => 'rw',
);

=head1 Operations on a block

=head2 disable

Disable the block:

    $Block->disable;

=head2 enable

Enable the block:

    $Block->enable;

=cut

sub disable { shift->_action( 'disable',@_ ); }
sub enable  { shift->_action( 'enable',@_ ); }

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
