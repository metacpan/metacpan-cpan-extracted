package Chart::GGPlot::Built;

# ABSTRACT: A processed ggplot that can be rendered

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0003'; # VERSION

use Data::Frame::Types qw(DataFrame);
use List::AllUtils qw(pairmap);
use Types::Standard qw(ArrayRef ConsumerOf);

use Chart::GGPlot::Types qw(:all);


has data          => ( is => 'ro', isa => ArrayRef [DataFrame] );
has prestats_data => ( is => 'ro', isa => ArrayRef [DataFrame] );
has layout        => ( is => 'ro', isa => ConsumerOf['Chart::GGPlot::Layout'] );
has plot          => ( is => 'ro', isa => ConsumerOf['Chart::GGPlot::Plot'] );


method layer_data ( $i = 0 ) {
    return $self->data->at($i);
}

method layer_prestats_data ( $i = 0 ) {
    return $self->prestats_data->at($i);
}

method layer_scales ( $i = 0, $j = 0 ) {
    my $layout = $self->layout->layout;

    my $which =
      ( which( $layout->at('ROW') == $i ) & which( $layout->at('COL') == $j ) );
    my $selected = $layout->select_rows($which);
    return {
        x => $self->layout->panel_scales_x->at( $selected->at('SCALE_X') ),
        y => $self->layout->panel_scales_y->at( $selected->at('SCALE_Y') ),
    };
}

#method summarize_layout () {
#    my $l = $self->layout;
#
#    my $layout =
#      [qw(panel row col)]->map( sub { $l->layout->at( uc( $_[0] ) ) } );
#
#    my $facet_vars = $l->facet->vars();
#
#    # Add a list-column of panel vars (for facets).
#    #$layout->at('vars') =
#
#    return $layout;
#}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Built - A processed ggplot that can be rendered

=head1 VERSION

version 0.0003

=head1 DESCRIPTION

This class represents a processed L<Chart::GGPlot::Plot> object that can
be rendered.
A L<Chart::GGPlot::Backend> consumer generates an object of this class as
an intermediate form during rendering a L<Chart::GGPlot::Plot> object.

=head1 ATTRIBUTES

=head2 data

An arrayref of data frames, each for a layer's processed data that would
later be used for rendering the plot.

=head2 prestats_data

An arrayref of data frames, each for a layer's processed data before stats
are applied. Some geom implementation of some graphics backends, like
Plotly's boxplot, may need this data.

=head2 layout

A L<Chart::GGPlot::Layout> object, which contains info about axis limits,
breaks, etc.

=head2 plot

The L<Chart::GGPlot::Plot> object from which the L<Chart::GGPlot::Built>
object is created.

=head1 METHODS

=head2 layer_data

    layer_data($i=0)

Helper function that returns the C<data> associated with a given layer.
C<$i> is the index of layer.

    my $data = $ggplot->layer_data(0);

=head2 layer_prestats_data

    layer_prestats_data($i=0)

Similar to the C<layer_data> method but is for C<prestats_data>.

=head2 layer_scales

    layer_scales($i=0, $j=0)

Helper function that returns the scales associated with a given layer.
Returns a hashref of x and y scales for the layer at row C<$i> and
column C<$j>.

=head1 SEE ALSO

L<Chart::GGPlot::Plot>,
L<Chart::GGPlot::Backend>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
