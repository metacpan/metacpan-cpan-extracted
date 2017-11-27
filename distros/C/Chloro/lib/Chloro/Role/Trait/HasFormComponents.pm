package Chloro::Role::Trait::HasFormComponents;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Moose::Role;

use Carp qw( croak );
use Tie::IxHash;

has _fields => (
    isa      => 'Tie::IxHash',
    init_arg => undef,
    default  => sub { Tie::IxHash->new() },
    handles  => {
        _add_field   => 'STORE',
        has_field    => 'EXISTS',
        get_field    => 'FETCH',
        local_fields => 'Values',
    },
);

has _groups => (
    isa      => 'Tie::IxHash',
    init_arg => undef,
    default  => sub { Tie::IxHash->new() },
    handles  => {
        _add_group   => 'STORE',
        has_group    => 'EXISTS',
        local_groups => 'Values',
    },
);

sub add_field {
    my $self  = shift;
    my $field = shift;

    if ( $self->has_field( $field->name() ) ) {
        my $name = $field->name();
        croak "Cannot add two fields with the same name ($name)";
    }

    if ( $self->has_group( $field->name() ) ) {
        my $name = $field->name();
        croak "Cannot share a name between a field and a group ($name)";
    }

    $self->_add_field( $field->name() => $field );

    return;
}

sub add_group {
    my $self  = shift;
    my $group = shift;

    if ( $self->has_group( $group->name() ) ) {
        my $name = $group->name();
        croak "Cannot add two groups with the same name ($name)";
    }

    if ( $self->has_field( $group->name() ) ) {
        my $name = $group->name();
        croak "Cannot share a name between a field and a group ($name)";
    }

    $self->_add_group( $group->name() => $group );

    return;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _make_field {
    my $self = shift;

    return Chloro::Field->new(
        name => shift,
        @_,
    );
}
## use critic

1;

# ABSTRACT: A metaclass trait for classes and roles which use Chloro

__END__

=pod

=encoding UTF-8

=head1 NAME

Chloro::Role::Trait::HasFormComponents - A metaclass trait for classes and roles which use Chloro

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This trait adds meta-information to classes and traits which C<use Chloro>.

=for Pod::Coverage add_field add_group

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Chloro> or via email to L<bug-chloro@rt.cpan.org|mailto:bug-chloro@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Chloro can be found at L<https://github.com/autarch/Chloro>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
