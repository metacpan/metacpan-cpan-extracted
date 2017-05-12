package Chart::OFC::Axis;
$Chart::OFC::Axis::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

with 'Chart::OFC::Role::OFCDataLines';

has text_size =>
    ( is      => 'ro',
      isa     => 'Int',
      default => 10,
    );

has text_color =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::Color',
      coerce  => 1,
      default => '#784016'
    );

has axis_color =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Color',
      coerce    => 1,
      predicate => '_has_axis_color',
    );

has grid_color =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Color',
      coerce    => 1,
      predicate => '_has_grid_color',
    );

has axis_label =>
    ( is       => 'ro',
      isa      => 'Chart::OFC::AxisLabel',
      coerce   => 1,
      required => 1,
    );

sub _ofc_data_lines { die 'This is a virtual method' }

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Base class for axis classes

__END__

=pod

=head1 NAME

Chart::OFC::Axis - Base class for axis classes

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This class is the base class for the X and Y axis classes. It provides
several attributes which are shared between these two subclasses.

=head1 ATTRIBUTES

This class has a number of attributes which may be passed to the
C<new()> method.

=head2 text_size

The size of tick labels for the axis, in pixels.

Defaults to 10.

=head2 text_color

The default color of tick labels.

Defaults to "#784016".

=head2 axis_color

The color of the axis line itself

This attribute is optional.

=head2 grid_color

The color of grid lines for this axis.

This attribute is optional.

=head2 axis_label

This is the label for the axis as a whole. This can be either a
string, a hash reference or an a C<Chart::OFC::AxisLabel> object.

If given a string or hash reference, the constructor will create a new
C<Chart::OFC::AxisLabel> object. If just a string is given, this is
used as the label text.

This attribute is required.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
