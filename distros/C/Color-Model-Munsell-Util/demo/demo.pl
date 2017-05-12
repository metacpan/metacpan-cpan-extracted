#!/usr/bin/perl
use warnings;
use strict;

use Color::Model::Munsell;
use Color::Model::Munsell::Util;

=head1 NAME

demo.pl - Demo program of Color::Model::Munsell::Util

=head1 SYNOPSIS

    perl demo.pl > some.html

=head1 DESCRIPTION

This demo program makes HTML file which contains sample colors table of
Munsell and converted to RGB Hex triplet of it.
Colors of this are from Macbeth ColorChecker colors and regulated
English-named colors by JIS (Japanese Industrial Standards) Z 8102:2001.

=cut

my $Title = "Demo of Color::Model::Munsell::Util";


# Load color data
my @Colors = ();
while (<DATA>){
    tr/\x0a\x0d//d;
    next unless $_;
    if ( /^#(.*)/ ){
        push @Colors, { title=> $1 };
        next;
    }
    my ($name, @d) = split(/\t/);
    push @Colors, {
        name => $name,
        m    => Color::Model::Munsell->new(@d)
    }
}

# make html
print <<__HTMLHEAD__;
<html>
<head>
    <title>$Title</title>
<style>
td {
    padding: 3px;
    font-family: monospace;
    text-align: center;
}
.c {
    width: 100px;
}
</style>
</head>
<body><h2>$Title</h2>
<table border="0" cellspacing="2">
<tr><th>Color Name</th><th>Munsell</th><th>sRGB</th><th>Apple RGB</th><th>PAL</th><th>Adobe RGB</th><th>NTSC</th></tr>
__HTMLHEAD__

foreach (@Colors){
    if ( defined($$_{title}) ){
        print qq(<tr><td colspan=7 style="background-color:#ccc"><em>$$_{title}</em></td></tr>\n);
        next;
    }
    my $m = $$_{m};
    print "<tr><td>$$_{name}</td><td>$m</td>";
    foreach my $model ( qw(sRGB AppleRGB PAL AdobeRGB NTSC) ){
        my $c = ( $m->value < 4 )? '#fff': '#000';
        my $bg= Munsell2RGB($m, $model);
        print qq(<td class="c" style="color:$c;background-color:#$bg">$bg</td>);
    }
    print "</tr>\n";
}

print <<__HTMLFOOT__;
</table>
</body>
</html>
__HTMLFOOT__



# data
__DATA__
# Macbeth ColorChecker
Macbeth1	3YR	3.7	3.2
Macbeth2	2.2YR	6.47	4.1
Macbeth3	4.3PB	4.95	5.5
Macbeth4	6.7GY	4.2	4.1
Macbeth5	9.7PB	5.47	6.7
Macbeth6	2.5BG	7	6
Macbeth7	5YR	6	11
Macbeth8	7.5PB	4	10.7
Macbeth9	2.5R	5	10
Macbeth10	5P	3	7
Macbeth11	5GY	7.1	9.1
Macbeth12	10YR	7	10.5
Macbeth13	7.5PB	2.9	12.7
Macbeth14	0.1G	5.4	9.6
Macbeth15	5R	4	12
Macbeth16	5Y	8	11.1
Macbeth17	2.5RP	5	12
Macbeth18	5B	5	8
Macbeth19	N	9.5
Macbeth20	N	8
Macbeth21	N	6.5
Macbeth22	N	5
Macbeth23	N	3.5
Macbeth24	N	2
# JIS Z 8102 - English color name
Rose Red	7.5RP	5	12
Rose pink	10RP	7	8
Cochineal Red	10RP	4	12
Ruby Red	10RP	4	14
Wine Red	10RP	3	9
Burgundy	10RP	2	2.5
Old Rose	1R	6	6.5
Rose	1R	5	14
Strawberry	1R	4	14
Coral Red	2.5R	7	11
Pink	2.5R	7	7
Bordeaux	2.5R	2.5	3
Baby Pink	4R	8.5	4
Poppy Red	4R	5	14
Signal Red	4R	4.5	14
Carmine	4R	4	14
Red	5R	5	14
Tomato Red	5R	5	14
Maroon	5R	2.5	6
Vermilion	6R	5.5	14
Scarlet	7R	5	14
Terracotta	7.5R	4.5	8
Salmon Pink	8R	7.5	7.5
Shell Pink	10R	8.5	3.5
Nail Pink	10R	8	4
Chinese Red	10R	6	15
Carrot Orange	10R	5	11
Burnt Sienna	10R	4.5	7.5
Chocolate	10R	2.5	2.5
Cocoa Brown	2YR	3.5	4
Peach	3YR	8	3.5
Raw Sienna	4YR	5	9
Orange	5YR	6.5	13
Brown	5YR	3.5	4
Apricot	6YR	7	6
Tan	6YR	5	6
Mandarin Orange	7YR	7	11.5
Cork	7YR	5.5	4
Ecru Beige	7.5YR	8.5	4
Golden Yellow	7.5YR	7	10
Marigold	8YR	7.5	13
Buff	8YR	6.5	5
Amber	8YR	5.5	6.5
Bronze	8.5YR	4	5
Beige	10YR	7	2.5
Yellow Ocher	10YR	6	7.5
Burnt Umber	10YR	3	3
Sepia	10YR	2.5	2
Khaki	1Y	5	5.5
Blond	2Y	7.5	7
Naples Yellow	2.5Y	8	7.5
Leghorn	2.5Y	8	4
Raw Umber	2.5Y	4	6
Chrome Yellow	3Y	8	12
Yellow	5Y	8.5	14
Cream Yellow	5Y	8.5	3.5
Jaune Brillant	5Y	8.5	14
Canary Yellow	7Y	8.5	10
Olive Drab	7.5Y	4	2
Olive	7.5Y	3.5	4
Lemon Yellow	8Y	8	12
Olive Green	2.5GY	3.5	3
Chartreuse Green	4GY	8	10
Leaf Green	5GY	6	7
Grass Green	5GY	5	5
Ivy Green	7.5GY	4	5
Apple Green	10GY	8	5
Mint Green	2.5G	7.5	8
Green	2.5G	5.5	10
Cobalt Green	4G	7	9
Emerald Green	4G	6	8
Malachite Green	4G	4.5	9
Bottle Green	5G	2.5	3
Forest Green	7.5G	4.5	5
Viridian	8G	4	6
Billiard Green	10G	2.5	5
Sea Green	6GY	7	8
Peacock Green	7.5BG	4.5	9
Nile Blue	10BG	5.5	5
Peacock Blue	10BG	4	8.5
Turquoise Blue	5B	6	8
Marine Blue	5B	3	7
Horizon Blue	7.5B	7	4
Cyan	7.5B	6	10
Sky Blue	9B	7.5	5.5
Cerulean Blue	9B	4.5	9
Baby Blue	10B	7.5	3
Saxe Blue	1PB	5	4.5
Blue	2.5PB	4.5	10
Cobalt Blue	3PB	4	10
Iron Blue	5PB	3	4
Prussian Blue	5PB	3	4
Midnight Blue	5PB	1.5	2
Hyacinth	5.5PB	5.5	6
Navy Blue	6PB	2.5	4
Ultramarine Blue	7.5PB	3.5	11
Oriental Blue	7.5PB	3	10
Wistaria	10PB	5	12
Pansy	1P	2.5	10
Heliotrope	2P	5	10.5
Violet	2.5P	4	11
Lavender	5P	6	3
Mauve	5P	4.5	9
Lilac	6P	7	6
Oechid	7.5P	7	6
Purple	7.5P	5	12
Magenta	5RP	5	14
Cherry Pink	6RP	5.5	11.5
White	N	9.5
Snow White	N	9.5
Ivory	2.5Y	8.5	1.5
Sky Grey	7.5B	7.5	0.5
Pearl Grey	N	7.0
silver Grey	N	6.5
Ash Grey	N	6.0
Rose Grey	2.5R	5.5	1
Grey	N	5.0
Steel Grey	5P	4.5	1
Slate Grey	2.5PB	3.5	0.5
Charcoal Grey	5P	3	1
Lamp Black	N	1.0
Black	N	1.0
