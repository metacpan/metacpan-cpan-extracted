use Data::Frame;
use PDL;
use Chart::Plotly qw(show_plot);

my $df = Data::Frame->new( columns => [
    x => pdl(1, 2, 3, 4),
    y => ( sequence(4) * sequence(4)  ) ,
] );

show_plot($df);
