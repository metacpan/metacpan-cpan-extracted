use Chart::Plotly qw(show_plot);
use Chart::Plotly::Trace::Scatter3d;
use English qw(-no_match_vars);
use Const::Fast;

const my $PI => 4 * atan2( 1, 1 );
const my $DELTA => 0.1;
my ( @x, @y, @z );
for ( my $u = 0; $u <= 2 * $PI; $u += $DELTA ) {
    for ( my $v = -1; $v < 1; $v += $DELTA ) {
        push @x, ( 1 + ( $v / 2 ) * cos( $u / 2 ) ) * cos($u);
        push @y, ( 1 + ( $v / 2 ) * cos( $u / 2 ) ) * sin($u);
        push @z, ( $v / 2 ) * sin( $u / 2 );
    }
}
my $scatter3d = Chart::Plotly::Trace::Scatter3d->new( x => \@x, y => \@y, z => \@z, mode => 'lines' );

show_plot( [$scatter3d] );

