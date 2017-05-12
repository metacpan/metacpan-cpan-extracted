#!/usr/bin/perl -w
use strict;
use Chart::Composite;    #(type is one of: Points, Lines, Bars, LinesPoints, Composite, StackedBars, Mountain)

print "1..1\n";
my $obj = Chart::Composite->new( 800, 600 );    #Breite, Höhe
my @legend_ary;
my ( $legend, @zeile );
my @all_aryref;
open( OUT, ">samples/composite_3.png" ) or die "kann Datei nicht schreiben\n";

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
    'max_val1'                  => $max_val,
    'max_val2'                  => $max_val,
    'space_bars'                => 1,
    'brush_size'                => 10,
    'legend_example_height'     => 'true',
    'legend_example_height0..3' => '50',
    'legend_example_height4..8' => '4',
);

$obj->png( \*OUT );
print "ok 1\n";
close OUT;

exit 0;

__END__
Datum|01.09.2003|02.09.2003|03.09.2003|04.09.2003|05.09.2003|06.09.2003|07.09.2003|08.09.2003|09.09.2003|10.09.2003|11.09.2003|12.09.2003|13.09.2003|14.09.2003|15.09.2003|16.09.2003|17.09.2003|18.09.2003|19.09.2003|20.09.2003|21.09.2003|22.09.2003
Anzahl gesamt|322|244|227|223|167|216|290|277|206|237|256|214|192|228|218|225|146|172|140|123|174|173
Anzahl  Stufe 1 bis 4 gesamt|226|173|159|145|109|148|204|188|133|184|176|137|132|157|139|155|106|115|93|76|107|106
Anzahl JL|77|46|44|61|41|54|69|63|63|38|71|68|54|59|71|61|34|40|42|38|56|57
Anzahl  DL|19|25|24|17|17|14|17|26|10|15|9|9|6|12|8|9|6|17|5|9|11|10
Anzahl  1.  Stufe|28|22|11|27|15|23|28|23|17|24|24|20|19|24|23|30|20|18|12|10|14|29
Anzahl  2. Stufe|12|11|4|7|8|6|16|12|8|11|10|8|4|8|3|6|7|6|5|7|8|13
Anzahl  3.  Stufe|50|39|55|34|16|33|38|40|36|38|48|29|35|42|36|42|28|25|20|19|24|19
Anzahl  4.  Stufe|136|101|89|77|70|86|122|113|72|111|94|80|74|83|77|77|51|66|56|40|61|45
Anzahl Formulars|547|352|249|174|138|157|262|180|136|132|94|72|59|129|88|60|61|51|42|44|79|57
EOF

