package Business::TrueLayer::Provider::Scheme;

=head1 NAME

Business::TrueLayer::Provider::Scheme - class representing a scheme
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $Scheme = Business::TrueLayer::Provider::Scheme->new(
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

=item allow_remitter_fee (Bool)

=back

=cut

has type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has allow_remitter_fee => (
    is       => 'ro',
    isa      => 'Bool',
    required => 0,
    default  => sub { 0 },
);

=head1 METHODS

None yet.

=head1 SEE ALSO

L<Business::TrueLayer::Provider::Scheme>

=cut

1;
