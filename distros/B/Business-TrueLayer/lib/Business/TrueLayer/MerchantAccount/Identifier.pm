package Business::TrueLayer::MerchantAccount::Identifier;

=head1 NAME

Business::TrueLayer::MerchantAccount::Identifier - class representing a
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
extends 'Business::TrueLayer::Account::Identifier';

=head1 SEE ALSO

L<Business::TrueLayer::Account::Identifier>

=cut

1;
