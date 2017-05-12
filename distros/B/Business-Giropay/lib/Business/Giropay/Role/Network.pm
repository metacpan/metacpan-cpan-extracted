package Business::Giropay::Role::Network;

=head1 NAME

Business::Giropay::Role::Network - 'network' role consumed by Core, Request and Response roles

=cut

use Business::Giropay::Types qw/Enum/;
use Moo::Role;

=head1 ATTRIBUTES

=head2 network

Network type. Currently the following are supported:

=over

=item * eps

=item * giropay

=item * ideal

=back

=cut

has network => (
    is       => 'ro',
    isa      => Enum [qw( eps giropay ideal)],
    required => 1,
);

1;
