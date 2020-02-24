package Bread::Board::LifeCycle::Session;

our $AUTHORITY = 'cpan:GSG';
# ABSTRACT: A short-lived singleton for Bread::Board
use version;
our $VERSION = 'v0.900.1'; # VERSION

use Moose::Role;
use Module::Runtime ();
use namespace::autoclean;

our $FLUSHER_ROLE = 'Bread::Board::Container::Role::WithSessions';

with 'Bread::Board::LifeCycle::Singleton';

### XXX: Lifecycle consumption happens after service construction,
### so we have pick a method that would get called after
### construction.  The 'get' method is pretty hot, so this should
### be done as fast as possible.

before get => sub {
    my $self = shift;

    # Assume we've already done this if an instance exists
    return if $self->has_instance;

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

Bread::Board::LifeCycle::Session - A short-lived singleton for Bread::Board

=head1 VERSION

version v0.900.1

=head1 SYNOPSIS

    use Bread::Board;

    my $c = container 'Reports' => as {
        service generic_report => (
            class     => 'Report',
            lifecycle => 'Session',
        );
    };

    sub dispatch {
        # ... dispatch code ...

        my $services_flushed = $c->flush_session_instances;
    }

=head1 DESCRIPTION

This implements a short-term "Session" lifecycle for Bread::Board.  Services with this lifecycle will exist as a singleton until they
are flushed with the L<flush_session_instances|Bread::Board::Container::Role::WithSessions/flush_session_instances> method.  The idea is
that this method would be called at the end of a web request, but a "session" could be defined as any sort of short-term cycle.

The L<Bread::Board::Container::Role::WithSessions> role is applied to all containers that exist in or around the service.

This module is similar to L<Bread::Board::LifeCycle::Request>, but has no connections to L<OX>.

=head1 ACKNOWLEDGEMENTS

Thanks to Grant Street Group L<http://www.grantstreet.com> for funding development of this code.

Thanks to Steve Grazzini (C<< <GRAZZ@CPAN.org> >>) for discussion of the concept.

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
