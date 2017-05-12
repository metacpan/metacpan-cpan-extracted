package Chart::OFC::Dataset::Line;
$Chart::OFC::Dataset::Line::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset';

# Cannot do has '+values' because the new type is not a subtype of the
# type in the parent class.
has 'values' =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::NonEmptyArrayRefOfNumsOrUndefs',
      required   => 1,
      auto_deref => 1,
    );

has width =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::PosInt',
      default => 2,
    );

has color =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::Color',
      coerce  => 1,
      default => '#000000',
    );

has label =>
    ( is        => 'ro',
      isa       => 'Str',
      predicate => '_has_label',
    );

has text_size =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::Size',
      default => 10,
    );

sub type
{
    return 'line';
}

sub _parameters_for_type
{
    my $self = shift;

    my @p = ( $self->width(), $self->color() );
    push @p, ( $self->label(), $self->text_size() )
        if $self->_has_label();

    return @p;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A dataset represented as a line

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::Line - A dataset represented as a line

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = (1, 2, 3);
    my $line    = Chart::OFC::Dataset::Line->new(
        values    => \@numbers,
        width     => 5,
        color     => 'purple',
        label     => 'Daily Sales in $',
        text_size => 12,
    );

=head1 DESCRIPTION

This class contains values to be charted as a line on a grid chart.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class has several attributes which may be passed to the C<new()>
method.

It is a subclass of C<Chart::OFC::Dataset> and accepts all of that
class's attributes as well as its own.

=head2 values

For this class, the values array may contain some undefined
values. These are simply skipped in the resulting chart.

=head2 links

Just as with values, this may contain some undefined values.

=head2 width

The width of the line in pixels.

Defaults to 2.

=head2 color

The color of the line, and of the text in the chart key, if a label is
specified.

Defaults to #999999 (medium grey).

=head2 label

If provided, this will be shown as part of the chart key.

This attribute is optional.

=head2 text_size

This is the size of the text in the key.

Defaults to 10 (pixels).

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
