package Business::GoCardless::TaxRate;

=head1 NAME

Business::GoCardless::TaxRate

=head1 DESCRIPTION

A class for a gocardless tax rate, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    end_date
    id
    jurisdiction
    percentage
    start_date
    type

=cut

has [ qw/
    end_date
    id
    jurisdiction
    percentage
    start_date
    type
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
