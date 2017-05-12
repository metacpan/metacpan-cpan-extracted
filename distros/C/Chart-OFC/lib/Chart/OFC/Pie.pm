package Chart::OFC::Pie;
$Chart::OFC::Pie::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC';

has dataset =>
    ( is       => 'ro',
      isa      => 'Chart::OFC::Dataset',
      required => 1,
    );

has slice_colors =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::NonEmptyArrayRefOfColors',
      coerce     => 1,
      lazy       => 1,
      default    => sub { [ qw( red blue green yellow orange purple black ) ] },
    );

has line_color =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::Color',
      coerce     => 1,
      default    => '#000000',
    );

has labels =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::NonEmptyArrayRef',
      required   => 1,
      auto_deref => 1,
    );

has label_style =>
    ( is      => 'ro',
      isa     => 'Str',
      default => 'color: #000000',
    );

has opacity =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::Opacity',
      default    => '80',
    );

sub BUILD
{
    my $self = shift;

    my @l = $self->labels();
    my @v = $self->dataset()->values();

    die 'You must have the same number of labels and values.'
        unless @l == @v;

    return;
}

override _ofc_data_lines => sub
{
    my $self = shift;

    return
        ( super(),
          $self->_data_line( 'pie',
                             $self->opacity(),
                             $self->line_color(),
                             $self->_formatted_label_style(),
                           ),
          $self->_data_line( 'pie_labels', $self->labels() ),
          $self->_data_line( 'colours', @{ $self->slice_colors() } ),
          $self->dataset()->_ofc_data_lines(),
        );
};

sub _formatted_label_style
{
    my $self = shift;

    my $style = $self->label_style();

    return unless length $style;

    return '{ ' . $self->label_style() . ' }';
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A pie chart

__END__

=pod

=head1 NAME

Chart::OFC::Pie - A pie chart

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my $dataset = Chart::OFC::Dataset->new( values => [ 1 .. 5 ] );
    my $pie = Chart::OFC::Pie->new(
        title   => 'My Pie Chart',
        dataset => $dataset,
    );

=head1 DESCRIPTION

This class represents a pie chart. A pie chart displays a single
dataset as a set of pie slices.

=for Pod::Coverage BUILD

=head1 ATTRIBUTES

This class is a subclass of C<Chart::OFC> and accepts all of that
class's attribute. It has several attributes of its own which may be
passed to the C<new()> method.

=head2 dataset

This should be a single dataset of the C<Chart::OFC::Dataset>
class. (It could be any Dataset subclass, but all the subclass's
attributes will be ignored).

This attribute is required.

=head2 slice_colors

This should an array of colors. If you give fewer colors than there
are in your dataset then colors will be reused (in order).

This defaults to "red, blue, green, yellow, orange, purple, black".

=head2 line_color

The colors of the lines which define slices.

Defaults to #000000 (black).

=head2 labels

This should be an array reference containing one or more labels for
the slices. This should contain one label per valuable in the dataset.

=head2 label_style

A snippet of CSS that will be applied to the labels. The default is
"color: #000000". If you change this you should probably make sure to
include a color.

=head2 opacity

This defines how opaque the slices are. When they are moused over, they
become fully opaque.

Defaults to 80 (percent).

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
