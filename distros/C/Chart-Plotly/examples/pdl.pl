use Chart::Plotly qw(show_plot);
use PDL;

use aliased 'Chart::Plotly::Trace::Surface';

my $size = 25;
my $x    = ( xvals zeroes $size+ 1, $size + 1 ) / $size;
my $y    = ( yvals zeroes $size+ 1, $size + 1 ) / $size;
my $z    = 0.5 + 0.5 * ( sin( $x * 6.3 ) * sin( $y * 6.3 ) )**3;    # Bumps

my $surface = Surface->new( x => $x, y => $y, z => $z );

show_plot([$surface]);

use PDL::Math;

my $bessel_size = 50;
my $bessel      = Surface->new(
    x => xvals($bessel_size),
    y => xvals($bessel_size),
    z => bessj0( rvals( zeroes( $bessel_size, $bessel_size ) ) / 2 )
);

show_plot([$bessel]);

