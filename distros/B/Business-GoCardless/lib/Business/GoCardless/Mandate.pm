package Business::GoCardless::Mandate;

=head1 NAME

Business::GoCardless::Mandate

=head1 DESCRIPTION

A class for a gocardless mandate, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    id

=cut

has [ qw/
    id
/ ] => (
    is => 'rw',
);


# TODO: finish

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
