package Business::TrueLayer::Beneficiary;

=head1 NAME

Business::TrueLayer::Beneficiary - class representing a beneficiary
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $Beneficiary = Business::TrueLayer::Beneficiary->new(
        name => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item type (Str)

=item account_holder_name (Str)

=item reference (Str)

=item merchant_account_id (Str) [optional]

=item verification (HashRef) [optional]

=back

=cut

has [ qw/
    type
    account_holder_name
    reference
/ ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [ qw/
    merchant_account_id
/ ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has verification => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 0,
);

=head1 METHODS

None yet.

=head1 SEE ALSO

=cut

1;
