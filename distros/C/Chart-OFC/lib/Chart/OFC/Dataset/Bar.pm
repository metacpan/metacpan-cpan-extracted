package Chart::OFC::Dataset::Bar;
$Chart::OFC::Dataset::Bar::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset';

has opacity =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::Opacity',
      default    => '80',
    );

has fill_color =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::Color',
      coerce  => 1,
      default => '#999999',
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
    return 'bar';
}

sub _parameters_for_type
{
    my $self = shift;

    my @p = ( $self->opacity(), $self->fill_color() );
    push @p, ( $self->label(), $self->text_size() )
        if $self->_has_label();

    return @p;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: A dataset represented as bars

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::Bar - A dataset represented as bars

=head1 VERSION

version 0.12

=head1 SYNOPSIS

   my @numbers = (1, 2, 3);
   my $bars    = Chart::OFC::Dataset::Bar->new(
       values     => \@numbers,
       opacity    => 60,
       fill_color => 'purple',
       label      => 'Daily Sales in $',
       text_size  => 12,
   );

=head1 DESCRIPTION

This class contains values to be charted as bars on a grid chart. The
bars are filled with the specified color, but have no outline or other
styling.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class has several attributes which may be passed to the C<new()>
method.

It is a subclass of C<Chart::OFC::Dataset> and accepts all of that
class's attributes as well as its own.

=head2 opacity

This defines how opaque the bars are. When they are moused over, they
become fully opaque.

Defaults to 80 (percent).

=head2 fill_color

The color used to fill the bars.

Defaults to #999999 (medium grey).

=head2 label

If provided, this will be shown as part of the chart key. The label
will be the same color as the fill_color for the bars.

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
