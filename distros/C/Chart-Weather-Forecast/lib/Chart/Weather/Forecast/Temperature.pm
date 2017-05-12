use strictures 1;
package Chart::Weather::Forecast::Temperature;
BEGIN {
  $Chart::Weather::Forecast::Temperature::VERSION = '0.04';
}
use Moose;
use namespace::autoclean;
use MooseX::Types::Path::Class;

use Chart::Clicker;
use Chart::Clicker::Data::Range;
use Chart::Clicker::Data::Series;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Drawing::ColorAllocator;
use Geometry::Primitive::Circle;
use Graphics::Primitive::Font;
use Graphics::Color::RGB;
use Number::Format;
use List::Util qw/ min max /;
use Path::Class qw/ file /;

use Data::Dumper::Concise;

=head1 Synopsis

    my $highs = [37, 28, 17, 22, 28];
    my $lows  = [18, 14,  5, 10, 18];
    
    my $forecast = Chart::Weather::Forecast::Temperature->new(
        highs      => $highs,
        lows       => $lows,
        chart_temperature_file => '/tmp/temperature_forecast.png',
    );
    $forecast->create_chart;

=head1 Attributes

=head2 highs

ArrayRef[Num] of high temperatures

    Required at construction (new): yes

=head2 lows

ArrayRef[Num] of low temperatures

    Required at construction (new): yes

=head2 chart_temperature_file

Where you want to write out the chart image.

    Default: /tmp/temperature-forecast.png' on *nix
    
NOTE: The chart_temperature_file attribute isa 'Path::Class::File'
so if you want to specifiy an output file then do so like:

   chart_temperature_file => Path::Class::File->new( $your_dir, $your_file_name);
   chart_temperature_file => Path::Class::File->new( '/tmp/', 'forecast_temps.png');

=head2 chart_width

Chart dimension in pixels

    Default: 240

=head2 chart_height

Chart dimension in pixels

    Default: 160

=head2 chart_format

Format of the chart image

    Default: png
    
=head2 title_text

The text to title the chart with.

    Default: Temperature Forecast

=cut

has 'highs' => (
    is       => 'rw',
    isa      => 'ArrayRef[Num]',
    required => 1,
);
has 'lows' => (
    is       => 'rw',
    isa      => 'ArrayRef[Num]',
    required => 1,
);
has 'chart_temperature_file' => (
    is        => 'ro',
    isa       => 'Path::Class::File',
    required  => 1,
    coerce    => 1,
    'default' => sub {  Path::Class::File->new(File::Spec->tmpdir, 'temperature-forecast.png') },
);
has 'chart_format' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'png' },
);

has 'chart_width' => (
    is      => 'ro',
    isa     => 'Int',
    default => 240,
);
has 'chart_height' => (
    is      => 'ro',
    isa     => 'Int',
    default => 160,
);

has 'title_text' => (
    is        => 'rw',
    isa       => 'Str',
    'default' => sub {
        my $self = shift;
        return $self->number_of_datum . '-Day Temperature Forecast';
    },
);
has 'title_font' => (
    is        => 'rw',
    isa       => 'Graphics::Primitive::Font',
    'default' => sub {
        Graphics::Primitive::Font->new(
            {
                family         => 'Trebuchet',
                size           => 11,
                antialias_mode => 'subpixel',
                hint_style     => 'medium',

            }
        );
    },
);
has 'tick_font' => (
    is        => 'rw',
    isa       => 'Graphics::Primitive::Font',
    'default' => sub {
        Graphics::Primitive::Font->new(
            {
                family         => 'Trebuchet',
                size           => 11,
                antialias_mode => 'subpixel',
                hint_style     => 'medium',

            }
        );
    },
);

has 'number_formatter' => (
    is        => 'ro',
    isa       => 'Number::Format',
    'default' => sub { Number::Format->new },
);

has 'freezing_line' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Data::Series',
    lazy      => 1,
    'default' => sub {
        my $self = shift;
        Chart::Clicker::Data::Series->new(
            keys =>  $self->x_values,
            values => [ (32) x $self->number_of_datum ],
        );
    },
);
has 'zero_line' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Data::Series',
    lazy      => 1,
    'default' => sub {
        my $self = shift;
        Chart::Clicker::Data::Series->new(
            keys =>  $self->x_values,
            values => [ (0) x $self->number_of_datum ],
        );
    },
);
has 'high_series' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Data::Series',
    lazy      => 1,
    'default' => sub {
        my $self = shift;
        Chart::Clicker::Data::Series->new(
            keys   => $self->x_values,
            values => $self->highs,
        );
    },
);
has 'low_series' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Data::Series',
    lazy      => 1,
    'default' => sub {
        my $self = shift;
        Chart::Clicker::Data::Series->new(
            keys   => $self->x_values,
            values => $self->lows,
        );
    },
);
has 'chart' => (
    is         => 'ro',
    isa        => 'Chart::Clicker',
    lazy_build => 1,
);
has 'default_ctx' => (
    is         => 'ro',
    isa        => 'Chart::Clicker::Context',
    lazy_build => 1,
);
has 'colors' => (
    is         => 'ro',
    isa        => 'HashRef[Graphics::Color::RGB]',
    lazy_build => 1,
);
has 'dataset' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Data::DataSet',
    'default' => sub {
        Chart::Clicker::Data::DataSet->new;
    },
);
has 'color_allocator' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Drawing::ColorAllocator',
    'default' => sub {
        Chart::Clicker::Drawing::ColorAllocator->new;
    },
);
has 'min_range' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range',
);
has 'max_range' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range',
);
has 'min_range_padded' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range_padded',
);
has 'max_range_padded' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range_padded',
);
has 'range_ticks' => (
    is         => 'ro',
    isa        => 'ArrayRef[Int]',
    lazy_build => 1,
);
has 'domain' => (
    is         => 'ro',
    isa        => 'Chart::Clicker::Data::Range',
    lazy_build => 1,
);
has 'range' => (
    is         => 'ro',
    isa        => 'Chart::Clicker::Data::Range',
    lazy_build => 1,
);
has 'number_of_datum' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);
has 'x_values' => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    lazy_build => 1,
);



=head1 Methods

=head2 create_chart

This is the main method to call on an object to create a chart.

=cut

sub create_chart {
    my $self = shift;

    # Add high series data set and color it red
    $self->dataset->add_to_series( $self->high_series );
    $self->color_allocator->add_to_colors( $self->colors->{red} );
    
    # Add low series data set and color it blue
    $self->dataset->add_to_series( $self->low_series );
    $self->color_allocator->add_to_colors( $self->colors->{blue} );

    # Add freezing line when appropriate.
    if ( $self->min_range_padded <= 32 ) {
        $self->dataset->add_to_series( $self->freezing_line );
        $self->color_allocator->add_to_colors( $self->colors->{light_blue} );
    }

    # Add zero line when appropriate.
    if ( $self->min_range_padded <= 0 ) {
        $self->dataset->add_to_series( $self->zero_line );
        $self->color_allocator->add_to_colors( $self->colors->{light_blue} );
    }

    # add the dataset to the chart
    $self->chart->add_to_datasets( $self->dataset );

    # assign the color allocator to the chart
    $self->chart->color_allocator( $self->color_allocator );

    # write the chart to a file
    $self->chart->write_output( $self->chart_temperature_file );

}

# Compute the max and min values for the y-axis (range).

sub _compute_range {
    my $self = shift;

    my $min_temperature = min @{ $self->lows };
    my $max_temperature = max @{ $self->highs };

    # Find nearest factor of 10 above and below
    $max_temperature += 10 - ( $max_temperature % 10 );
    $min_temperature -= ( $min_temperature % 10 );

    return ( $min_temperature, $max_temperature );
}

sub _build_domain {
    my $self = shift;

    my $fudge_factor = 0.25;
    return Chart::Clicker::Data::Range->new(
        {
            lower => (1 - $fudge_factor),
            upper => ($self->number_of_datum + $fudge_factor),
        }
    );
}

sub _build_range {
    my $self = shift;

    return Chart::Clicker::Data::Range->new(
        {
            lower => $self->min_range_padded,
            upper => $self->max_range_padded,
        }
    );
}

sub _build_x_values {
    my $self = shift;
    
    return [1..$self->number_of_datum];
}

# Add just a touch of padding in case a value is right on the computed range.
# This keeps data from being cropped off in the graph.

sub _pad_range {
    my ( $self, $padding ) = @_;
    $padding ||= 2;

    return ( ( $self->min_range - $padding ), ( $self->max_range + $padding ) );
}


# Determine where the ticks for the y-axis will be based on the high and low temperatures.
# We coerce the ticks into integers for readability.

sub _build_range_ticks {
    my ($self) = @_;

    my $delta = $self->max_range - $self->min_range;
    my $tens  = int( $delta / 10 );
    my @ticks = ( int $self->min_range );
    for my $factor ( 1 .. $tens ) {
        push @ticks, ( ( int $self->min_range ) + ( $factor * 10 ) );
    }
    return \@ticks;
}

sub _build_y_range {
    my $self = shift;

    my ( $min_range, $max_range ) = $self->_compute_range;
    $self->min_range($min_range);
    $self->max_range($max_range);

    return;
}

sub _build_y_range_padded {
    my $self = shift;

    my ( $min_range_padded, $max_range_padded ) = $self->_pad_range;
    $self->min_range_padded($min_range_padded);
    $self->max_range_padded($max_range_padded);

    return;
}

sub _build_number_of_datum {
    my $self = shift;

    my $nbr_of_lows  = scalar @{$self->lows};
    my $nbr_of_highs = scalar @{$self->highs};
    
    if ( $nbr_of_lows != $nbr_of_highs ) {
        die "ERROR:  You need to have the same number of high and low values";
    }
    else {
        return $nbr_of_highs;
    }
}

sub _build_colors {
    my $self = shift;

    {
        red => Graphics::Color::RGB->new(
            {
                red   => .75,
                green => 0,
                blue  => 0,
                alpha => .8
            }
        ),
        blue => Graphics::Color::RGB->new(
            {
                red   => 0,
                green => 0,
                blue  => .75,
                alpha => .8
            }
        ),
        light_blue => Graphics::Color::RGB->new(
            {
                red   => 0,
                green => 0,
                blue  => .95,
                alpha => .16
            }
        ),
    };
}

##-- Builders
sub _build_chart {
    my $self = shift;

    # Create the chart canvas
    my $chart = Chart::Clicker->new(
        width  => $self->chart_width,
        height => $self->chart_height,
        format => $self->chart_format,
    );

    # Title
    $chart->title->text( $self->title_text );
    $chart->title->font( $self->title_font );

    # Tufte influenced customizations (maximize data-to-ink)
    $chart->grid_over(1);
    $chart->plot->grid->show_range(0);
    $chart->plot->grid->show_domain(0);
    $chart->legend->visible(0);
    $chart->border->width(0);

    return $chart;
}

sub _build_default_ctx {
    my $self = shift;

    my $default_ctx = $self->chart->get_context('default');

    # Set number format of axis
    $default_ctx->domain_axis->format(
        sub { return $self->number_formatter->format_number(shift); } );
    $default_ctx->range_axis->format(
        sub { return $self->number_formatter->format_number(shift); } );
        
    # Set font of ticks
    $default_ctx->domain_axis->tick_font( $self->tick_font );
    $default_ctx->range_axis->tick_font( $self->tick_font );
    
    # The chart type is a "connect the dots" (line segments between data circles)
    $default_ctx->renderer( Chart::Clicker::Renderer::Line->new );
    $default_ctx->renderer->shape(
        Geometry::Primitive::Circle->new( { radius => 3, } ) );
    $default_ctx->renderer->brush->width(1);
    
    # Set ticks values for each axis
    $default_ctx->domain_axis->tick_values( $self->x_values );
    $default_ctx->range_axis->tick_values( $self->range_ticks );

    # Set max and min values for each axis.
    $default_ctx->domain_axis->range($self->domain);
    $default_ctx->range_axis->range($self->range);

    return $default_ctx;
}

=head2 BUILD

Here we do some initialization just after the object has been constructed.
Calling these builders here helped me defeat undef occuring from lazy dependencies.

=cut

sub BUILD {
    my $self = shift;
    
    $self->_build_y_range;
    $self->_build_y_range_padded;
    $self->_build_default_ctx;
}

__PACKAGE__->meta->make_immutable;
1

__END__

=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2010, Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut
