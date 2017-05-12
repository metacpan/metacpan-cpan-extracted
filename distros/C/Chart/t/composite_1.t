#!/usr/bin/perl -w

use Chart::Composite;
print "1..1\n";

my $obj = Chart::Composite->new( 600, 500 );
my @legend_ary;
my ( $legend, @zeile );
my @all_aryref;
open( OUT, ">samples/composite_1.png" ) or die "cannot write file samples/composite_1.png\n";

my $i       = 0;
my $e       = 0;
my $max_val = 0;
while (<DATA>)
{
    if ( $_ =~ /EOF/i )
    {
        last;
    }
    chomp;
    $i++;
    ( $legend, @zeile ) = split /\|/, $_;
    $obj->add_dataset(@zeile);
    if ( $i != 1 )
    {
        push @legend_ary, $legend;    # Erste Zeile ist die x-Achsenbezeichnung und gehört nicht zur Legende
        for ( 0 .. $#zeile ) { $zeile[$_] > $max_val ? $max_val = $zeile[$_] : 1; }    # den Maximalen Wert ermitteln
    }
    $all_aryref[ $e++ ] = [@zeile];

}

if ( $max_val =~ /^\d+$/ )
{

    $max_val = 100 * int( 1 + $max_val / 100 );
}    # den Scalenwert die nächste 100er Stellen setzen

# Der zweite Charttyp überdeckt immer den ersten
$obj->set(
    'legend'                    => "top",
    'legend_labels'             => \@legend_ary,
    'x_ticks'                   => "vertical",
    'composite_info'            => [ [ 'StackedBars', [ 8, 7, 6, 5 ] ], [ 'Bars', [ 1, 2, 3, 4, 9 ] ], ],
    'same_y_axes'               => "true",
    'y_label'                   => "Anzahl",
    'min_val1'                  => 0,
    'max_val1'                  => $max_val,
    'max_val2'                  => $max_val,
    'space_bars'                => 1,
    'brush_size'                => 10,
    'legend'                    => 'bottom',
    'title'                     => 'Composite Demo Chart',
    'legend_example_height'     => 'true',
    'legend_example_height0..3' => '50',
    'legend_example_height4..9' => '4',
);
$obj->png( \*OUT );
close OUT;
print "ok 1\n";
exit 0;

__END__
Datum|01.09.2003|02.09.2003|03.09.2003|04.09.2003
Anzahl gesamt|322|244|227|223
Anzahl  Stufe 1 bis 4 gesamt|226|173|159|145
Anzahl JL|77|46|44|61
Anzahl  DL|19|25|24|17            
Anzahl  1. Stufe|28|22|11|27
Anzahl  2. Stufe|12|11|4|7
Anzahl  3. Stufe|50|39|55|34
Anzahl  4. Stufe|136|101|89|77
Anzahl Formulare|547|352|249|174
EOF

