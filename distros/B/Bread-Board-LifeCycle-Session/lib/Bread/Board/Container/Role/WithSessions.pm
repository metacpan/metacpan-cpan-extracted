package Bread::Board::Container::Role::WithSessions;

our $AUTHORITY = 'cpan:GSG';
our $VERSION   = '0.90';

use Moose::Role;
use namespace::autoclean;
use List::Util 1.33 ('any');

our @LIFECYCLES_TO_FLUSH = qw(
    Session
    Session::WithParameters
    +Bread::Board::LifeCycle::Session
    +Bread::Board::LifeCycle::Session::WithParameters
);

sub flush_session_instances {
    my $self = shift;

    my @containers = ($self);
    my $flush_count = 0;

    # Traverse the sub containers to find any Session services
    while (my $container = shift @containers) {
        push @containers, values %{$container->sub_containers};
        foreach my $service (values %{$container->services}) {
            next unless defined $service->lifecycle;
            next unless any { $service->lifecycle eq $_ } @LIFECYCLES_TO_FLUSH;
            next unless (
                $service->can('has_instance') && $service->has_instance ||
                $service->can('instances')    && values $service->instances
            );

            $service->flush_instance  if $service->can('flush_instance');
            $service->flush_instances if $service->can('flush_instances');
            $flush_count++;
        }
    };

    return $flush_count;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::Container::Role::WithSessions

=head1 VERSION

version 0.90

=head1 DESCRIPTION

This role defines Session helper methods for Containers.

=head1 METHODS

=head2 flush_session_instances

This method clears all Session instances from the container and any sub-containers.  In most cases, this should be called on the root
container, but it can be called on a sub-container, if you want to only clear out services within that container.

If successful, it will return the number of services that were flushed.  Note that this may be zero.
