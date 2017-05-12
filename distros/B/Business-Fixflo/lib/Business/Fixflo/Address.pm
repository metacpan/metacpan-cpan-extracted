package Business::Fixflo::Address;

=head1 NAME

Business::Fixflo::Address

=head1 DESCRIPTION

A class for a fixflo address, extends L<Business::Fixflo::Resource>

=cut

use strict;
use warnings;

use Moo;
use Business::Fixflo::Exception;
use Business::Fixflo::Envelope;

extends 'Business::Fixflo::Resource';

has [ qw/
    AddressLine1
    AddressLine2
    Town
    County
    PostCode
    Country
/ ] => (
    is => 'rw',
);

# there are (currently) no possible operations on an Address so we have a
# "null" client to override the client attribute from the Resource class
has client => (
    is       => 'ro',
    isa      => sub { 1 },
    default  => sub { 0 },
    required => 0,
);

=head1 Operations on an address

N/A

=cut

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-fixflo

=cut

1;

# vim: ts=4:sw=4:et
