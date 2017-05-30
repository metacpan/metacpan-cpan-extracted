package Chart::Plotly::Trace::Histogram2dcontour;
use Moose;
use MooseX::ExtraArgs;

use Chart::Plotly::Trace::Attribute::Colorbar;
use Chart::Plotly::Trace::Attribute::Contours;
use Chart::Plotly::Trace::Attribute::Line;
use Chart::Plotly::Trace::Attribute::Marker;
use Chart::Plotly::Trace::Attribute::Xbins;
use Chart::Plotly::Trace::Attribute::Ybins;

our $VERSION = '0.013';    # VERSION

sub TO_JSON {
    my $self       = shift;
    my $extra_args = $self->extra_args // {};
    my %hash       = ( %$self, %$extra_args );
    delete $hash{'extra_args'};
    if ( $self->can('type') && ( !defined $hash{'type'} ) ) {
        $hash{type} = $self->type();
    }
    return \%hash;
}

has autobinx => (
    is  => 'rw',
    isa => "Bool",
    documentation =>
      "Determines whether or not the x axis bin attributes are picked by an algorithm. Note that this should be set to false if you want to manually set the number of bins using the attributes in xbins.",
);

has autobiny => (
    is  => 'rw',
    isa => "Bool",
    documentation =>
      "Determines whether or not the y axis bin attributes are picked by an algorithm. Note that this should be set to false if you want to manually set the number of bins using the attributes in ybins.",
);

has autocolorscale => (
            is            => 'rw',
            isa           => "Bool",
            documentation => "Determines whether or not the colorscale is picked using the sign of the input z values.",
);

has autocontour => (
    is  => 'rw',
    isa => "Bool",
    documentation =>
      "Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.",
);

has colorbar => ( is  => 'rw',
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Colorbar" );

has colorscale => (
    is => 'rw',
    documentation =>
      "Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax",
);

has contours => ( is  => 'rw',
                  isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Contours" );

has histfunc => (
    is => 'rw',
    documentation =>
      "Specifies the binning function used for this histogram trace. If *count*, the histogram values are computed by counting the number of values lying inside each bin. If *sum*, *avg*, *min*, *max*, the histogram values are computed using the sum, the average, the minimum or the maximum of the values lying inside each bin respectively.",
);

has histnorm => (
    is => 'rw',
    documentation =>
      "Specifies the type of normalization used for this histogram trace. If **, the span of each bar corresponds to the number of occurrences (i.e. the number of data points lying inside the bins). If *percent*, the span of each bar corresponds to the percentage of occurrences with respect to the total number of sample points (here, the sum of all bin area equals 100%). If *density*, the span of each bar corresponds to the number of occurrences in a bin divided by the size of the bin interval (here, the sum of all bin area equals the total number of sample points). If *probability density*, the span of each bar corresponds to the probability that an event will fall into the corresponding bin (here, the sum of all bin area equals 1).",
);

has line => ( is  => 'rw',
              isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Line" );

has marker => ( is  => 'rw',
                isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Marker" );

has nbinsx => (
    is => 'rw',
    documentation =>
      "Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data.",
);

has nbinsy => (
    is => 'rw',
    documentation =>
      "Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data.",
);

has ncontours => (
    is => 'rw',
    documentation =>
      "Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true*.",
);

has reversescale => ( is            => 'rw',
                      isa           => "Bool",
                      documentation => "Reverses the colorscale.",
);

has showscale => ( is            => 'rw',
                   isa           => "Bool",
                   documentation => "Determines whether or not a colorbar is displayed for this trace.",
);

has x => ( is            => 'rw',
           documentation => "Sets the sample data to be binned on the x axis.", );

has xbins => ( is  => 'rw',
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Xbins" );

has y => ( is            => 'rw',
           documentation => "Sets the sample data to be binned on the y axis.", );

has ybins => ( is  => 'rw',
               isa => "Maybe[HashRef]|Chart::Plotly::Trace::Attribute::Ybins" );

has z => ( is            => 'rw',
           documentation => "Sets the aggregation data.", );

has zauto => (
          is            => 'rw',
          isa           => "Bool",
          documentation => "Determines the whether or not the color domain is computed with respect to the input data.",
);

has zmax => ( is            => 'rw',
              isa           => "Num",
              documentation => "Sets the upper bound of color domain.",
);

has zmin => ( is            => 'rw',
              isa           => "Num",
              documentation => "Sets the lower bound of color domain.",
);

has name => ( is            => 'rw',
              isa           => "Str",
              documentation => "Sets the trace name",
);

sub type {
    my @components = split( /::/, __PACKAGE__ );
    return lc( $components[-1] );
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Plotly::Trace::Histogram2dcontour

=head1 VERSION

version 0.013

=head1 SYNOPSIS

 use HTML::Show;
 use Chart::Plotly;
 use Chart::Plotly::Trace::Histogram2dcontour;
 my $histogram2dcontour =
   Chart::Plotly::Trace::Histogram2dcontour->new( x => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ],
                                                  y => [ map { int( 10 * rand() ) } ( 1 .. 500 ) ] );
 
 HTML::Show::show( Chart::Plotly::render_full_html( data => [$histogram2dcontour] ) );

=head1 DESCRIPTION

This file has been autogenerated from the official plotly.js source.

If you like Plotly, please support them: L<https://plot.ly/> 
Open source announcement: L<https://plot.ly/javascript/open-source-announcement/>

Full reference: L<https://plot.ly/javascript/reference/#histogram2dcontour>

=head1 NAME 

Chart::Plotly::Trace::Histogram2dcontour

=head1 DISCLAIMER

This is an unofficial Plotly Perl module. Currently I'm not affiliated in any way with Plotly. 
But I think plotly.js is a great library and I want to use it with perl.

=head1 METHODS

=head2 TO_JSON

Serialize the trace to JSON. This method should be called only by L<JSON> serializer.

=head1 ATTRIBUTES

=over

=item * autobinx

Determines whether or not the x axis bin attributes are picked by an algorithm. Note that this should be set to false if you want to manually set the number of bins using the attributes in xbins.

=item * autobiny

Determines whether or not the y axis bin attributes are picked by an algorithm. Note that this should be set to false if you want to manually set the number of bins using the attributes in ybins.

=item * autocolorscale

Determines whether or not the colorscale is picked using the sign of the input z values.

=item * autocontour

Determines whether or not the contour level attributes are picked by an algorithm. If *true*, the number of contour levels can be set in `ncontours`. If *false*, set the contour level attributes in `contours`.

=item * colorbar

=item * colorscale

Sets the colorscale. The colorscale must be an array containing arrays mapping a normalized value to an rgb, rgba, hex, hsl, hsv, or named color string. At minimum, a mapping for the lowest (0) and highest (1) values are required. For example, `[[0, 'rgb(0,0,255)', [1, 'rgb(255,0,0)']]`. To control the bounds of the colorscale in z space, use zmin and zmax

=item * contours

=item * histfunc

Specifies the binning function used for this histogram trace. If *count*, the histogram values are computed by counting the number of values lying inside each bin. If *sum*, *avg*, *min*, *max*, the histogram values are computed using the sum, the average, the minimum or the maximum of the values lying inside each bin respectively.

=item * histnorm

Specifies the type of normalization used for this histogram trace. If **, the span of each bar corresponds to the number of occurrences (i.e. the number of data points lying inside the bins). If *percent*, the span of each bar corresponds to the percentage of occurrences with respect to the total number of sample points (here, the sum of all bin area equals 100%). If *density*, the span of each bar corresponds to the number of occurrences in a bin divided by the size of the bin interval (here, the sum of all bin area equals the total number of sample points). If *probability density*, the span of each bar corresponds to the probability that an event will fall into the corresponding bin (here, the sum of all bin area equals 1).

=item * line

=item * marker

=item * nbinsx

Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data.

=item * nbinsy

Specifies the maximum number of desired bins. This value will be used in an algorithm that will decide the optimal bin size such that the histogram best visualizes the distribution of the data.

=item * ncontours

Sets the maximum number of contour levels. The actual number of contours will be chosen automatically to be less than or equal to the value of `ncontours`. Has an effect only if `autocontour` is *true*.

=item * reversescale

Reverses the colorscale.

=item * showscale

Determines whether or not a colorbar is displayed for this trace.

=item * x

Sets the sample data to be binned on the x axis.

=item * xbins

=item * y

Sets the sample data to be binned on the y axis.

=item * ybins

=item * z

Sets the aggregation data.

=item * zauto

Determines the whether or not the color domain is computed with respect to the input data.

=item * zmax

Sets the upper bound of color domain.

=item * zmin

Sets the lower bound of color domain.

=item * name

Sets the trace name

=back

=head2 type

Trace type.

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
