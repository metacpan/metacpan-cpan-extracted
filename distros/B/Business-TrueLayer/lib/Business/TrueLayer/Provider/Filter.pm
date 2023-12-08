package Business::TrueLayer::Provider::Filter;

=head1 NAME

Business::TrueLayer::Provider::Filter - class representing a provider
filter as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $Filter = Business::TrueLayer::Provider::Filter->new(
        countries => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use Complete::Country qw/ complete_country_code /;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item release_channel (Str)

=item customer_segments (ArrayRef[Str])

=item countries (ArrayRef[Country])

Where Country is Alpha-2 ISO 3166 country code (e.g. "DE")

=back

=cut

has [ qw/ release_channel / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

my @iso_codes = map { uc( $_->{word} ) }
    complete_country_code()->@*;

enum 'Country' => \@iso_codes;

has [ qw/ countries / ] => (
    is       => 'ro',
    isa      => 'ArrayRef[Country]',
    required => 1,
);

has [ qw/ customer_segments / ] => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);

=head1 METHODS

None yet.

=head1 SEE ALSO

L<Business::TrueLayer::Provider::Scheme>

=cut

1;
