package Business::TrueLayer::Address;

=head1 NAME

Business::TrueLayer::Address - class representing an address
as used in the TrueLayer v3 API.

https://docs.truelayer.com/docs/merchant-accounts-1

=head1 SYNOPSIS

    my $Address = Business::TrueLayer::Address->new(
        type => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
no warnings qw/ experimental::signatures experimental::postderef /;

=head1 ATTRIBUTES

=over

=item address_line1 (Str)

=item city (Str)

=item state (Str)

=item zip (Str)

=item country_code (Str)

=back

=cut

has [ qw/ address_line1 city state zip country_code / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head1 METHODS

None yet.

=head1 SEE ALSO

=cut

1;
