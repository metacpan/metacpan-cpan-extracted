package Business::GoCardless::User;

=head1 NAME

Business::GoCardless::User

=head1 DESCRIPTION

A class for a gocardless user, extends L<Business::GoCardless::Resource>

=cut

use strict;
use warnings;

use Moo;
extends 'Business::GoCardless::Resource';

=head1 ATTRIBUTES

    created_at
    email
    first_name
    id
    last_name

=cut

has [ qw/
    created_at
    email
    first_name
    id
    last_name
/ ] => (
    is => 'rw',
);

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
