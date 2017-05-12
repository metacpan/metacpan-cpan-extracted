use Chart::Plotly 'show_plot';

my $data = { x    => [ 1 .. 10 ],
             mode => 'markers',
             type => 'scatter'
};
$data->{'y'} = [ map { rand 10 } @{ $data->{'x'} } ];


use aliased 'Chart::Plotly::Trace::Scattergl';

my $big_array = [ 1 .. 10000 ];
my $scattergl = Scattergl->new( x => $big_array, y => [ map { rand 100 } @$big_array ] );

use PDL;
use PDL::Math;
use aliased 'Chart::Plotly::Trace::Surface';

my $bessel_size = 50;
my $bessel      = Surface->new(
    x => xvals($bessel_size),
    y => xvals($bessel_size),
    z => bessj0( rvals( zeroes( $bessel_size, $bessel_size ) ) / 2 )
);

use Data::Table;

my $table = Data::Table::fromFile('morley.csv');

show_plot([$data], [$scattergl], [$bessel], $table);
