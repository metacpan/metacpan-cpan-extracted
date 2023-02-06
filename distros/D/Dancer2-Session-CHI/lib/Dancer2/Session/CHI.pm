package Dancer2::Session::CHI;
# ABSTRACT: Dancer 2 session storage with CHI backend

use strict;
use warnings;

use Moo;
use CHI;
use Type::Tiny;
use Types::Standard qw/ Str ArrayRef InstanceOf HashRef/;

#
# Public attributes
#
has 'driver' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'driver_args' => (
    is       => 'ro',
    isa      => HashRef,
    required => 0,
);

#
# Private attributes
#
has _chi => (
    is      => 'lazy',
    isa     => InstanceOf ['CHI::Driver'],
    handles => {
        _destroy => 'remove',
    },
);

# Session methods
sub _retrieve {
    my ($self) = shift;

    return $self->_chi->get( @_ );
}

sub _flush {
    my ($self) = shift;

    return $self->_chi->set( @_ );
}

sub _build__chi {
    my ($self) = @_;

    return CHI->new(
        driver => $self->driver,
        %{ $self->driver_args },
    );
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my @args  = @_;

    my %chi_args = @args;
    delete $chi_args{ $_ } foreach qw( postponed_hooks log_cb session_dir driver );
    push @args, 'driver_args', \%chi_args;
    return $class->$orig( @args );
};

#
# Role composition
#
with 'Dancer2::Core::Role::SessionFactory';

sub _sessions { my $self = shift; return $self->_chi->get_keys; }

sub _change_id {
    my ( $self, $old_id, $new_id ) = @_;
    $self->_flush( $new_id, $self->_retrieve( $old_id ) );
    $self->_destroy( $old_id );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Session::CHI - Dancer 2 session storage with CHI backend

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    # In Dancer 2 config.yml file
    session: CHI
    engines:
        session:
            CHI:
                driver: FastMmap
                root_dir: '/tmp/dancer-sessions'
                cache_size: 1k

=head1 DESCRIPTION

This module implements a session factory for L<Dancer2> that stores session
state using L<CHI>.

=head1 ATTRIBUTES

=head2 driver (required)

The backend driver CHI will use to store the session data. Any additional
attributes beyond the driver will be passed as additional configuration
parameters to CHI.

=for Pod::Coverage method_names_here

=head1 SEE ALSO

=over 4

=item * L<CHI>

=item * L<Dancer2>

=back

=head1 CREDITS

This is heavily based on L<Dancer2::Session::Memcached> by David Golden and
Yanick Champoux.

=head2 Contributors

The following people have contributed to C<Dancer2::Session::CHI> in some way,
either through bug reports, code, suggestions, or moral support:

=over

=item andk

=item Mohammad S Anwar

=back

=head1 AUTHOR

Jason A. Crome <cromedome@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Jason A. Crome.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
