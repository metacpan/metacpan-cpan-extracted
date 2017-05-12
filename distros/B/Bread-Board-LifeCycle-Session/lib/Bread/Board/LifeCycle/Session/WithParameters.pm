package Bread::Board::LifeCycle::Session::WithParameters;

our $AUTHORITY = 'cpan:GSG';
our $VERSION   = '0.90';

use Moose::Role;
use Module::Runtime ();
use namespace::autoclean;

our $FLUSHER_ROLE = 'Bread::Board::Container::Role::WithSessions';

with 'Bread::Board::LifeCycle::Singleton::WithParameters';

### XXX: Lifecycle consumption happens after service construction,
### so we have pick a method that would get called after
### construction.  The 'get' method is pretty hot, so this should
### be done as fast as possible.

before get => sub {
    my $self = shift;

    # Assume we've already done this if any instance exists
    return if values $self->instances;

    Module::Runtime::require_module($FLUSHER_ROLE);

    my @containers = ($self->get_root_container);

    # Traverse the sub containers and apply the WithSessions role
    while (my $container = shift @containers) {
        push @containers, values %{$container->sub_containers};

        Class::MOP::class_of($FLUSHER_ROLE)->apply($container)
            unless $container->meta->does_role($FLUSHER_ROLE);
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Board::LifeCycle::Session::WithParameters

=head1 VERSION

version 0.90

=head1 DESCRIPTION

This lifecycle type is a flushable version of L<Bread::Board::LifeCycle::Singleton::WithParameters>.  Like
L<Session|Bread::Board::LifeCycle::Session>, the same L<flush_session_instances|Bread::Board::Container::Role::WithSessions/flush_session_instances>
method is applied to all of its containers.
