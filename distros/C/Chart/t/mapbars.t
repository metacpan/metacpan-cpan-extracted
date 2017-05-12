use strict;
use Chart::Bars;

my $png_name = 'samples/mapbars.png';
my @legend_keys = ( "Actual ", "Goal" );

my $Graph = new Chart::Bars( 600, 400 );

print "1..1\n";

$Graph->add_dataset(
    "Oct 01", "Nov 01", "Dec 01", "Jan 02", "Feb 02", "Mar
02"
);
$Graph->add_dataset( 95.1, 84.4, 90.2, 94.4, 93.8, 95.5 );
$Graph->add_dataset( 93.0, 83.0, 94.0, 94.0, 94.0, 94.0 );

$Graph->set(
    composite_info => [ [ 'Bars', [1] ], [ 'Lines', [2] ] ],
    colors => {
        dataset0 => 'green',
        dataset1 => 'red'
    },
    title_font         => GD::Font->Giant,
    label_font         => GD::Font->Small,
    legend_font        => GD::Font->Large,
    tick_label_font    => GD::Font->Large,
    grid_lines         => 'true',
    graph_border       => 0,
    imagemap           => 'true',
    legend             => 'bottom',
    legend_labels      => \@legend_keys,
    max_val            => 100,
    min_val            => 80,
    png_border         => 4,
    same_y_axes        => 'true',
    spaced_bars        => 'true',
    title              => "Yield 2004",
    text_space         => 5,
    transparent        => 'true',
    x_ticks            => 'vertical',
    integer_ticks_only => 'true',
    skip_int_ticks     => 5,
);

$Graph->png("$png_name");

my $imagemap_data = $Graph->imagemap_dump();

foreach my $ds ( 1 .. 1 )
{
    foreach my $pt ( 0 .. 5 )
    {
        my @i = @{ $imagemap_data->[$ds]->[$pt] };    # **
        print "Dataset:$ds - Point: $pt  ----  VALUES: @i \n";
    }
}
print "ok 1\n";

exit 0;
