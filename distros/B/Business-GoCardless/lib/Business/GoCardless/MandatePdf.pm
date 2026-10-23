package Business::GoCardless::MandatePdf;

=head1 NAME

Business::GoCardless::MandatePdf

=head1 DESCRIPTION

A class for a gocardless mandate pdf, extends L<Business::GoCardless::Resource>

Note that the C<url> is temporary and expires after C<expires_at>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    expires_at
    url

=cut

has [ qw/
    expires_at
    url
/ ] => (
    is => 'rw',
);

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
