package Chart::OFC::Dataset::Area;
$Chart::OFC::Dataset::Area::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset::Line';

has dot_size =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::PosInt',
      default => 5,
    );

has opacity =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::Opacity',
      default    => '80',
    );

has fill_color =>
    ( is        => 'ro',
      isa       => 'Chart::OFC::Type::Color',
      coerce    => 1,
      predicate => '_has_fill_color',
    );

sub type
{
    return 'area_hollow';
}

sub _parameters_for_type
{
    my $self = shift;

    my @p = ( $self->width(), $self->dot_size(), $self->opacity(), $self->color() );

    push @p, ( $self->label(), $self->text_size() )
        if $self->_has_label();

    push @p, $self->fill_color()
        if $self->_has_fill_color();

    return @p;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: A dataset represented as a line with a filled area

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::Area - A dataset represented as a line with a filled area

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = (1, 2, 3);
    my $bars    = Chart::OFC::Dataset::Area->new(
        values     => \@numbers,
        dot_size   => 3,
        opacity    => 60,
        color      => 'blue',
        fill_color => 'purple',
        label      => 'Daily Sales in $',
        text_size  => 12,
    );

=head1 DESCRIPTION

This class contains values to be charted as a dotted line with a
filled area between the line and the X axis.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class has several attributes which may be passed to the C<new()>
method.

It is a subclass of C<Chart::OFC::Dataset::Line> and accepts all of
that class's attributes as well as its own.

=head2 opacity

This defines how opaque the bars are. When they are moused over, they
become fully opaque.

Defaults to 80 (percent).

=head2 fill_color

The color used to fill the area between the line and the X axis.

This attribute is optional. If it is not provided, then OFC uses the
color of the line itself (set with the C<color> attribute).

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
