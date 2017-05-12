package Chart::OFC::Dataset::LineWithDots;
$Chart::OFC::Dataset::LineWithDots::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset::Line';

has solid_dots =>
    ( is      => 'ro',
      isa     => 'Bool',
      default => 1,
    );

has dot_size =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::PosInt',
      default => 5,
    );

sub type
{
    my $self = shift;

    return $self->solid_dots() ? 'line_dot' : 'line_hollow';
}

sub _parameters_for_type
{
    my $self = shift;

    my @p = ( $self->width(), $self->color() );
    push @p, ( $self->label(), $self->text_size(), $self->dot_size() )
        if $self->_has_label();

    return @p;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: A dataset represented as a line with dots for each value

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::LineWithDots - A dataset represented as a line with dots for each value

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = (1, 2, 3);
    my $line    = Chart::OFC::Dataset::Line->new(
        values     => \@numbers,
        width      => 5,
        color      => 'purple',
        label      => 'Daily Sales in $',
        text_size  => 12,
        solid_dots => 1,
    );

=head1 DESCRIPTION

This class contains values to be charted as a line on a grid chart.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class has several attributes which may be passed to the C<new()>
method.

It is a subclass of C<Chart::OFC::Dataset::Line> and accepts all of
that class's attributes as well as its own.

=head2 solid_dots

If true, the dots are solid, if not they are hollow.

Defaults to true.

=head2 dot_size

The size of the dots in pixels.

Defaults to 5.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
