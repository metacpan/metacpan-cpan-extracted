package Announcements::Announcing;
use Moose::Role;
use Announcements::SubscriptionRegistry;

has _subscription_registry => (
    is       => 'ro',
    isa      => 'Announcements::SubscriptionRegistry',
    lazy     => 1,
    required => 1,
    default  => sub { Announcements::SubscriptionRegistry->new },
    handles  => ['add_subscription'],
);

sub announce {
    my $self = shift;
    my $announcement = shift;
    $self->_subscription_registry->announce($announcement, $self);
}

1;

__END__

=head1 NAME

Announcements::Announcing - role for objects which announce events

=cut

