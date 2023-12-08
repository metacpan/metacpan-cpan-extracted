package Business::TrueLayer::MerchantAccount;

=head1 NAME

Business::TrueLayer::MerchantAccount - class representing a merchant account
as used in the TrueLayer v3 API.

https://docs.truelayer.com/docs/merchant-accounts-1

=head1 SYNOPSIS

    my $MerchantAccount = Business::TrueLayer::MerchantAccount->new(
        id => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::MerchantAccount::Identifier;

=head1 ATTRIBUTES

=over

=item id (Str)

=item currency (Str)

=item account_holder_name (Str)

=item available_balance_in_minor (Num)

=item current_balance_in_minor (Num)

=item account_identifiers

An array ref of L<Business::TrueLayer::MerchantAccount::Identifier> objects

=back

=cut

has [ qw/ id currency account_holder_name / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [ qw/
    available_balance_in_minor
    current_balance_in_minor
/ ] => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

subtype 'AccountIdentifier'
    => as 'Object'
    => where {
        $_->isa( 'Business::TrueLayer::MerchantAccount::Identifier' )
    }
;

coerce 'AccountIdentifier'
    => from 'HashRef'
    => via {
        Business::TrueLayer::MerchantAccount::Identifier->new( %{ $_ } );
    }
;

subtype 'AccountIdentifiers'
    => as 'ArrayRef[AccountIdentifier]'
;

coerce 'AccountIdentifiers'
    => from 'ArrayRef'
    => via {
        my @AccountIdentifiers;
        foreach my $item ( $_->@* ) {
            push(
                @AccountIdentifiers,
                Business::TrueLayer::MerchantAccount::Identifier->new( %{ $item } )
            );
        }

        return \@AccountIdentifiers;
    }
;

has 'account_identifiers' => (
    is       => 'ro',
    isa      => 'AccountIdentifiers',
    coerce   => 1,
    required => 1,
);

=head1 METHODS

None yet. TODO:

    transactions
    payment_sources

=head1 SEE ALSO

L<Business::TrueLayer::MerchantAccount::Identifier>

=cut

1;
