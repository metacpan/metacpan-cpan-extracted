package Business::TrueLayer::MerchantAccount::Identifier;

=head1 NAME

Business::TrueLayer::MerchantAccount::Identifier - class representing a merchant
account identifier as used in the TrueLayer v3 API.

https://docs.truelayer.com/docs/merchant-accounts-1

=head1 SYNOPSIS

    my $MerchantAccount = Business::TrueLayer::MerchantAccount::Identifier->new(
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

=item type (Str)

=item iban (Str)

=item account_number (Str)

=item sort_code (Str)

An array ref of L<Business::TrueLayer::MerchantAccount::Identifier> objects

=back

=cut

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [ qw/ iban account_number sort_code / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

=head1 METHODS

None yet.

=head1 SEE ALSO

L<Business::TrueLayer::MerchantAccount>

=cut

1;
