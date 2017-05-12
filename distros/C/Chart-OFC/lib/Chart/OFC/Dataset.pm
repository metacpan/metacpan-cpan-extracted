package Chart::OFC::Dataset;
$Chart::OFC::Dataset::VERSION = '0.12';
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use Chart::OFC::Types;

with 'Chart::OFC::Role::OFCDataLines';

has 'values' =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::NonEmptyArrayRefOfNums',
      required   => 1,
      auto_deref => 1,
    );

has 'links' =>
    ( is         => 'ro',
      isa        => 'Chart::OFC::Type::NonEmptyArrayRef',
      required   => 0,
      auto_deref => 1,
      predicate  => 'has_links',
    );

sub _ofc_data_lines
{
    my $self  = shift;
    my $count = shift;

    my @lines;
    if ( $self->can('type') )
    {
        my $name = $self->type();
        $name .= q{_} . $count
            if $count && $count > 1;

        push @lines,
            $self->_data_line( $name, $self->_parameters_for_type() );
    }

    my $val_name = 'values';
    $val_name .= q{_} . $count
        if $count && $count > 1;

    push @lines,
        $self->_data_line( $val_name, $self->values() );

    if ( $self->has_links() )
    {
        my $links_name = 'links';
        $links_name .= q{_} . $count
            if $count && $count > 1;

        push @lines, $self->_data_line( $links_name, $self->links() );
    }

    return @lines;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;


# ABSTRACT: A set of values to be charted

__END__

=pod

=head1 NAME

Chart::OFC::Dataset - A set of values to be charted

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    my @numbers = (1, 2, 3);
    my $dataset = Chart::OFC::Dataset->new( values => \@numbers );

=head1 DESCRIPTION

This class represents a set of values that will be charted along the X
axis of a chart (or as pie slices).

=head1 ATTRIBUTES

This class has one attribute which may be passed to the C<new()>
method.

=head2 values

This should be an array reference containing one more numbers
representing values to be plotted on the chart. On grid charts, these
are plotted on the X axis.

This attribute is required, and must contain at least one value.

=head2 links

This is an optional attribute which may be an array reference of
links, one per value.

=head1 ROLES

This class does the C<Chart::OFC::Role::OFCDataLines> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
