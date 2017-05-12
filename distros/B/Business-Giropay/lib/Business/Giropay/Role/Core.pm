package Business::Giropay::Role::Core;

=head1 NAME

Business::Giropay::Role::Core - common attributes consumed by several classes and roles

=cut

use Business::Giropay::Types qw/Bool Enum HashRef Int Str/;
use Carp;

use Moo::Role;

=head1 ATTRIBUTES

=head2 merchantId

The Giropay merchant ID.

=cut

has merchantId => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

=head2 projectId

The Giropay project ID.

=cut

has projectId => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

=head2 sandbox

Defaults to false. Set this to true during testing. This provides very limited
protection since Giropay test transactions are routed through the same server
as real transactions. B<BEWARE!>

=cut

has sandbox => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head2 secret

The Giropay shared secret for this L</merchantId> and L</projectId>,

=cut

has secret => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;
