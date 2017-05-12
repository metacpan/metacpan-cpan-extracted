package Chart::OFC::Grid;
$Chart::OFC::Grid::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC';

has datasets =>
    ( is       => 'ro',
      isa      => 'Chart::OFC::Type::NonEmptyArrayRefOfTypedDatasets',
      required => 1,
    );

has x_axis =>
    ( is       => 'ro',
      isa      => 'Chart::OFC::XAxis',
      required => 1,
    );

has y_axis =>
    ( is       => 'ro',
      isa      => 'Chart::OFC::YAxis',
      required => 1,
    );

has inner_bg_color =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Color',
      coerce    => 1,
      predicate => '_has_inner_bg_color',
    );

has inner_bg_color2 =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Color',
      coerce    => 1,
      predicate => '_has_inner_bg_color2',
    );

has inner_bg_fade_angle =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Angle',
      predicate => '_has_inner_bg_fade_angle',
    );


sub BUILD
{
    my $self = shift;

    die "You cannot set an inner background fade angle unless you set two background colors"
        if $self->_has_inner_bg_fade_angle()
           && ! ( $self->_has_inner_bg_color() && $self->_has_inner_bg_color2() );

    die "You cannot set a second inner background color unless you set a first color and a fade angle"
        if $self->_has_inner_bg_color2()
           && ! ( $self->_has_inner_bg_color() && $self->_has_inner_bg_fade_angle );

    return;
}

override _ofc_data_lines => sub
{
    my $self = shift;

    my $x = 1;
    return
        ( super(),
          $self->_inner_background_line(),
          $self->x_axis()->_ofc_data_lines(),
          $self->y_axis()->_ofc_data_lines(),
          map { $_->_ofc_data_lines($x++) } @{ $self->datasets() },
        );
};

sub _inner_background_line
{
    my $self = shift;

    return unless $self->_has_inner_bg_color();

    my @vals = $self->inner_bg_color();

    if ( $self->_has_inner_bg_color2() )
    {
        push @vals, $self->inner_bg_color2(), $self->inner_bg_fade_angle();
    }

    return $self->_data_line( 'inner_background', @vals );
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: A grid chart

__END__

=pod

=head1 NAME

Chart::OFC::Grid - A grid chart

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my $bars = Chart::OFC::Dataset::Bar->new( values => [ 1 .. 5 ] );
    my $line = Chart::OFC::Dataset::Line->new( values => [ 2 .. 7 ] );

    my $x_axis = Chart::OFC::XAxis->new( axis_label => 'X Axis' );
    my $y_axis = Chart::OFC::YAxis->new(
        axis_label  => 'Y Axis',
        max         => 10,
        label_steps => 2
    );

    my $grid = Chart::OFC::Grid->new(
        title    => 'My Grid Chart',
        datasets => [ $bars, $line ],
        x_axis   => $x_axis,
        y_axis   => $y_axis,
    );

=head1 DESCRIPTION

This class represents a grid chart. A grid chart can contain any
combination of bars, lines, and area lines.

It also has an X and a Y axis.

=for Pod::Coverage BUILD

=head1 ATTRIBUTES

This class is a subclass of C<Chart::OFC> and accepts all of that
class's attribute. It has several attributes of its own which may be
passed to the C<new()> method.

=head2 datasets

This should be an array reference containing at least one dataset. The
datasets can be of any type I<except> C<Class::OFC::Dataset> (the base
class). Instead, they must be objects of some Dataset subclass.

This attribute is required.

=head2 x_axis

This should be a C<Chart::OFC::XAxis> object.

This attribute is required.

=head2 y_axis

This should be a C<Chart::OFC::YAxis> object.

This attribute is required.

=head2 inner_bg_color

The background color for just the chart itself, as opposed to the
surrounding text.

This attribute is optional.

=head2 inner_bg_color2

If this is provided, then OFC will implement a fade between the two
inner background colors. If you provide this you must also provide an
C<inner_bg_fade_angle> attribute.

This attribute is optional.

=head2 inner_bg_fade_angle

A number from 0 to 359 specifying the angle of the fade between the
two background colors. If you provide this you must also provide two
inner background colors.

This attribute is optional.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
