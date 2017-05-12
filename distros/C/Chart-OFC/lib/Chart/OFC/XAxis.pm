package Chart::OFC::XAxis;
$Chart::OFC::XAxis::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Axis';


has labels =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::NonEmptyArrayRef',
      predicate => '_has_labels',
    );

has label_steps =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::PosInt',
      default => 1,
    );

has tick_steps =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::PosInt',
      predicate => '_has_tick_steps',
    );

has three_d_height =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::PosInt',
      predicate => '_has_three_d_height',
    );

has orientation =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::Orientation',
      default => 'horizontal',
    );

my %Orientation = ( horizontal => 0,
                    vertical   => 1,
                    diagonal   => 2,
                  );
sub _ofc_data_lines
{
    my $self = shift;

    my @lines = $self->axis_label()->_ofc_data_lines('x');

    push @lines, $self->_data_line( 'x_labels', @{ $self->labels() } )
        if $self->_has_labels();

    push @lines, $self->_data_line( 'x_label_style',
                                    $self->text_size(),
                                    $self->text_color(),
                                    $Orientation{ $self->orientation() },
                                    $self->label_steps(),
                                    ( $self->_has_grid_color() ? $self->grid_color() : () ),
                                  );

    push @lines, $self->_data_line( 'x_ticks', $self->tick_steps() )
        if $self->_has_tick_steps();

    push @lines, $self->_data_line( 'x_axis_3d', $self->three_d_height() )
        if $self->_has_three_d_height();

    push @lines, $self->_data_line( 'x_axis_color', $self->axis_color() )
        if $self->_has_axis_color();

    push @lines, $self->_data_line( 'x_axis_steps', $self->tick_steps() )
        if $self->_has_tick_steps();

    return @lines;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: X axis for grid charts

__END__

=pod

=head1 NAME

Chart::OFC::XAxis - X axis for grid charts

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This class represents the X axis for a grid chart.

=head1 ATTRIBUTES

This class is a subclass of C<Chart::OFC::Axis> and accepts all of
that class's attribute. It has several attributes of its own which may
be passed to the C<new()> method.

=head2 labels

This should be an array reference containing one or more labels for
the X axis.

This attribute is optional.

=head2 label_steps

Show a label every N values.

This defaults to 1, but you should change this for large datasets.

=head2 tick_steps

Show a tick every N values.

This attribute is optional. OFC seems to do a reasonably good job of
calculating a default.

=head2 three_d_height

Setting this to some integer makes the X axis display with a 3D
effect. You should set this if your chart contains 3D bars.

=head2 orientation

This can be one of "horizontal", "vertical", or "diagonal". According
to the OFC docs, Unicode characters will only display properly
horizontally.

Defaults to "horizontal".

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
