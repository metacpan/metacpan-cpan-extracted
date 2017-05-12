package Chart::OFC::Dataset::Scatter;
$Chart::OFC::Dataset::Scatter::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

extends 'Chart::OFC::Dataset::Line';

has values =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::NonEmptyArrayRefOfArrayRefsOfNumsOrUndefs',
      required   => 1,
      auto_deref => 1,
    );

has circle_size =>
    ( is      => 'ro',
      isa     => 'Chart::OFC::Type::PosInt',
      default => 5,
    );

sub type
{
    return 'scatter';
}

sub _parameters_for_type
{
    my $self = shift;

    my @p = ( $self->width(), $self->color() );

    push @p, ( $self->label(), $self->text_size(), $self->circle_size() )
        if $self->_has_label();

    return @p;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A dataset represented as a scatter plot point for each value

__END__

=pod

=head1 NAME

Chart::OFC::Dataset::Scatter - A dataset represented as a scatter plot point for each value

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = ( [ 1, 2, 3 ], [ 3, 2, 1 ] );
    my $scatter = Chart::OFC::Dataset::Scatter->new(
        values      => \@numbers,
        width       => 5,
        color       => 'purple',
        label       => 'Daily Sales in $',
        text_size   => 12,
        circle_size => 10,
    );

=head1 DESCRIPTION

This class contains values to be charted as scatter points on a grid chart.

=for Pod::Coverage type

=head1 ATTRIBUTES

This class has several attributes which may be passed to the C<new()>
method.

It is a subclass of C<Chart::OFC::Dataset::Line> and accepts all of
that class's attributes as well as its own.

=head2 values

This dataset accepts an arrayref which in turn contains one or more
array references, each of which contains a set of values.

=head2 circle_size

This is included for compatibility with OFC, but does not seem to effect
the chart.

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
