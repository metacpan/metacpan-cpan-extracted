package Benchmark::Chart;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Smart::Args;
use Chart::Gnuplot;

=head1 NAME

Benchmark::Chart - Plots your L<Benchmark>

=head1 VERSION

Version 0.01

=cut

use Exporter 'import';
our @EXPORT_OK = qw(plotthese);

our $VERSION = '0.01';


=head1 SYNOPSIS

Benchmark::Chart plots your Benchmark(s) using Gnuplot.
If you are not familiar with module L<Benchmark>, please study that first.

Common usage:

    use Benchmark qw/:all/;
    use Benchmark::Chart qw/plotthese/;
    
    sub createSubs {
        my $x = shift;
        return {
            'x * x' => sub { $x * $x },
            'x ^ 2' => sub { $x**2 },
        };
    }
    
    # functional interface
    my $result = timethese( 20000000, createSubs( 9467443 ), 'none' );
    plotthese(
        options => {
            title  => "My cool benchmark",
            output => "benchmark1.png",
        },
        data => $result
    );
    
    # or if you have more data
    my %inputs = (
        '9999999'               => 9999999,
        '88888888888'           => 88888888888,
        '777777777777777777777' => 777777777777777777777,
    );
    
    my @results;
    for my $k ( keys %inputs ) {
        push @results, { $k => timethese( 20000000, createSubs( $inputs{$k} ), 'none' ) };
    }
    
    plotthese(
        options => {
            title  => "My cool benchmark",
            output => "benchmark2.png",
        },
        data => \@results
    );

=head1 EXPORT

plotthese on demand

=head1 SUBROUTINES/METHODS

=head2 plotthese

=over 1

=item options

Arguments passed to L<Chart::Gnuplot>, see L<Chart::Gnuplot> fore more information.

=item uniform [Bool]

If true and plotting multiple benchmarks, then the performence will be converted to %.

=item data [HashRef|ArrayRef]

=over 5

=item data is HashRef

Single benchmark: data is Hash containing Benchmarks as values and keys as a labels.

=item data is ArrayRef

Multiple benchmarks. Array items are hashes with keys as a labels of benchmarked data, values are
HashRefs (data is HashRef above).

=back

=back

=cut

sub _new {
    args( my $class, my $data => { isa => 'Ref', optional => 1 } );

    return bless { data => $data }, $class;
}

sub data {
    args( my $self, my $data => { isa => 'Ref', optional => 1 } );
    if ( $data ) {
        $self->{data} = $data;
    }
    return $self->{data};
}

sub _calculateRate {
    args( my $self, my $benchmark => 'Benchmark' );

    if ( $benchmark->cpu_p == 0 ) {
        return 0;
    }
    else {
        my $r =  1 / ($benchmark->cpu_p / $benchmark->iters);
        return $r;
    }
}

sub _plotMultiple {
    args( my $self, my $options => 'HashRef' );

    my $chart = Chart::Gnuplot->new( %$options );

    my %cases;
    for my $benchmark ( @{ $self->data } ) {
        if ( ref $benchmark ne 'HASH' ) {
            warn "Benchmark case `$benchmark' is not a HASH reference, ignoring";
            next;
        }

        my ( $name, $b ) = %{$benchmark};

        if ( ref $b ne 'HASH' ) {
            warn "Benchmark case `$b' is not a HASH reference, ignoring";
            next;
        }

        my $max = 0;
        my @y;
        for my $key ( keys $b ) {
            $cases{$key}->{$name} = $self->_calculateRate( benchmark => $b->{$key} );
            if ( $cases{$key}->{$name} > $max ) {
                $max = $cases{$key}->{$name};
            }
        }

        if ( $self->{uniform} && $max > 0) {
            for my $key ( keys $b ) {
                $cases{$key}->{$name} = $cases{$key}->{$name} / $max * 100;
            }
        }
    }

    my @datasets;
    for my $key ( keys %cases ) {
        push @datasets,
            Chart::Gnuplot::DataSet->new(
            xdata => [ keys %{ $cases{$key} } ],
            xtics => undef,
            ydata => [ values %{ $cases{$key} } ],
            style => "histograms",
            title => $key
            );
    }
    
    $chart->plot2d( @datasets );
}

sub _plotSingle {
    args( my $self, my $options => 'HashRef' );

    # Create chart object and specify the properties of the chart
    my $chart = Chart::Gnuplot->new( %$options );

    my @x, my @y;
    for my $case ( keys %{ $self->data } ) {
        my $benchmarkCase = $self->data->{$case};

        if ( ref $benchmarkCase ne 'Benchmark' ) {
            warn "Benchmark case `$case' is not a Benchmark object, ignoring";
            next;
        }

        my $rate = $self->_calculateRate( benchmark => $benchmarkCase );
        push @x, $case;
        push @y, $rate;
    }

    my $dataset = Chart::Gnuplot::DataSet->new(
        xdata => \@x,
        xtics => undef,
        ydata => \@y,
        style => "histograms"
    );

    # Plot the data set on the chart
    $chart->plot2d( $dataset );
}
sub _plot {
    args(
        my $self, my $options => 'HashRef',
        my $uniform => { isa => 'Bool', optional => '1', default => 0 }
    );

    if ( !$self->data ) {
        warn "No benchmark to process!";
        return 0;
    }

    $self->{uniform} = $uniform;


    my $type       = ref $self->data;
    my $singleFlag = $type eq 'HASH';
    my $ylabel = "performance ";
    $ylabel .= ( $uniform && !$singleFlag ) ? "[%]" : "[op/sec]";

    my %defaultOptions = (
        output => "out.png",
        xtics  => {
            offset => ( $singleFlag ) ? 2 : 0,
            length => "0"
        },
        bg       => "white",
        auto     => 'x',
        yrange   => [ 0, '*' ],
        style    => 'data histogram',
        style    => 'histogram cluster gap 1',
        style    => 'fill solid border -1',
        ylabel   => $ylabel,
        boxwidth => 0.9,
        grid     => {
            ylines => "on",
            xlines => "off",
        },
        'xtic'    => 'rotate by -45 scale 0',
        timestamp => { fmt => '%d/%m/%y %H:%M', },
    );

    my %combinedOptions = ( %defaultOptions, %{$options} );

    if ( $type eq 'HASH' ) {
        $self->_plotSingle( options => \%combinedOptions );
    }
    elsif ( $type eq 'ARRAY' ) {
        $self->_plotMultiple( options => \%combinedOptions );
    }
    else {
        warn "Unrecognizable dataset";
    }
}

# cache
my $chartObject;

sub plotthese {
    args(
        my $options => 'HashRef',
        my $data    => 'Ref',
        my $uniform => { isa => 'Bool', optional => 1, default => 0 }
    );
    my $bc = _new Benchmark::Chart( data => $data );
    $bc->_plot( options => $options, uniform => $uniform );
}

=head1 AUTHOR

Tomas Dohnalek, C<< <dohnto at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2014 Tomas Dohnalek <dohnto@gmail.com> 

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO.

=cut

1;    # End of Benchmark::Chart
