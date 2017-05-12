package Chart::OFC::YAxis;
$Chart::OFC::YAxis::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Axis';


has min =>
    ( is      => 'ro',
      isa     => 'Num',
      default => 0,
    );

has max =>
    ( is       => 'ro',
      isa      => 'Num',
      required => 1,
    );

has small_tick_size =>
    ( is      => 'ro',
      isa     => 'Int',
      default => 5,
    );

has large_tick_size =>
    ( is      => 'ro',
      isa     => 'Int',
      default => 10,
    );

has label_steps =>
    ( is       => 'ro',
      isa      => 'Chart::OFC::Type::PosInt',
      required => 1,
    );

sub _ofc_data_lines
{
    my $self = shift;

    my @lines = $self->axis_label()->_ofc_data_lines('y');

    push @lines, $self->_data_line( 'y_label_style',
                                    $self->text_size(),
                                    $self->text_color(),
                                  );

    push @lines, $self->_data_line( 'y_ticks',
                                    $self->small_tick_size(),
                                    $self->large_tick_size(),
                                    int( ( $self->max() - $self->min() ) / $self->label_steps() ),
                                  );

    push @lines, $self->_data_line( 'y_min', $self->min() );

    push @lines, $self->_data_line( 'y_max', $self->max() );

    push @lines, $self->_data_line( 'y_axis_colour', $self->axis_color() )
        if $self->_has_axis_color();

    push @lines, $self->_data_line( 'y_grid_colour', $self->grid_color() )
        if $self->_has_grid_color();

    return @lines;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: Y axis for grid charts

__END__

=pod

=head1 NAME

Chart::OFC::YAxis - Y axis for grid charts

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This class represents the Y axis for a grid chart.

=head1 ATTRIBUTES

This class is a subclass of C<Chart::OFC::Axis> and accepts all of
that class's attribute. It has several attributes of its own which may
be passed to the C<new()> method.

Note that because its label is display vertically, Unicode characters
in the label will not display correctly, according to the OFC docs.

=head2 min

This is the minimum value to show on the Y axis. It must be a number.

Defaults to 0.

=head2 max

This is the maximum value to show on the Y axis. It must be a number.

This attribute is required.

=head2 small_tick_size

The size of a small tick, in pixels.

Defaults to 5.

=head2 large_tick_size

The size of a large tick, in pixels.

Defaults to 10.

=head2 label_steps

Show a label every N values.

This attribute is required.

Note that the definition of this attribute is different than how OFC
defines it, but is consistent with the same attribute for the X axis
(unlike OFC).

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
