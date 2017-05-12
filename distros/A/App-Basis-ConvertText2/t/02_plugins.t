#!/usr/bin/perl -w

=head1 NAME

app.t

=head1 DESCRIPTION

test App::Basis::Convert::Plugins

=head1 AUTHOR

 kevin mulholland, moodfarm@cpan.org

=cut

use v5.10;
use strict;
use warnings;
use Path::Tiny;
use Data::Printer;

use Test::More tests => 26;

BEGIN {
    # the first set of tests either use other perl modules
    # of have everything they need
    use_ok('App::Basis::ConvertText2::Plugin::Barcode');
    use_ok('App::Basis::ConvertText2::Plugin::Chart');
    use_ok('App::Basis::ConvertText2::Plugin::Sparkline');
    use_ok('App::Basis::ConvertText2::Plugin::Venn');
    use_ok('App::Basis::ConvertText2::Plugin::Text');

    # tests that require external programs can only be tested
    # by the author
SKIP: {
        if ( $ENV{AUTHOR_TESTING} ) {
            use_ok('App::Basis::ConvertText2::Plugin::Ditaa');
            use_ok('App::Basis::ConvertText2::Plugin::Graphviz');
            use_ok('App::Basis::ConvertText2::Plugin::Mscgen');
            use_ok('App::Basis::ConvertText2::Plugin::Uml');
            use_ok('App::Basis::ConvertText2::Plugin::Gle');
            use_ok('App::Basis::ConvertText2::Plugin::Gnuplot');
        }
        else {
            skip "Author external programs", 6;
        }
    }
}

my ( $obj, $out, $content, $params );
my $TEST_DIR = "/tmp/convert_text_$$";
path($TEST_DIR)->mkpath;

# -----------------------------------------------------------------------------

sub has_file {
    my ($data) = @_;
    return 0 if ( !$data );
    my ($file) = ( $data =~ /<img src='(.*?)'/ );

    return $file ? -f $file : 0;
}

# ----------------------------------------------------------------------------
# _extract_args
sub extract_args {
    my $buf = shift;
    my ( %attr, $eaten );
    return \%attr if ( !$buf );

    while ( $buf =~ s|^\s?(([a-zA-Z][a-zA-Z0-9\.\-_]*)\s*)|| ) {
        $eaten .= $1;
        my $attr = lc $2;
        my $val;

        # The attribute might take an optional value (first we
        # check for an unquoted value)
        if ( $buf =~ s|(^=\s*([^\"\'>\s][^>\s]*)\s*)|| ) {
            $eaten .= $1;
            $val = $2;

            # or quoted by " or '
        }
        elsif ( $buf =~ s|(^=\s*([\"\'])(.*?)\2\s*)||s ) {
            $eaten .= $1;
            $val = $3;

            # truncated just after the '=' or inside the attribute
        }
        elsif ($buf =~ m|^(=\s*)$|
            or $buf =~ m|^(=\s*[\"\'].*)|s )
        {
            $buf = "$eaten$1";
            last;
        }
        else {
            # assume attribute with implicit value
            $val = $attr;
        }
        $attr{$attr} = $val;
    }

    return \%attr;
}

# -----------------------------------------------------------------------------

# barcodes
$obj     = App::Basis::ConvertText2::Plugin::Barcode->new();
$content = '12345678';
$params  = { type => 'ean8' };
$out     = $obj->process( 'barcode', $content, $params, $TEST_DIR );
ok( has_file($out), 'barcode created a file' );
$content = 'http://news.bbc.co.uk';
$params  = { height => 50, version => 2 };
$out     = $obj->process( 'qrcode', $content, $params, $TEST_DIR );
ok( has_file($out), 'qrcode created a file' );

# chart
$obj     = App::Basis::ConvertText2::Plugin::Chart->new();
$content = "apples,bananas,cake,cabbage,edam,fromage,tomatoes,chips
1,2,3,5,11,22,33,55
1,2,3,5,11,22,33,55
1,2,3,5,11,22,33,55
1,2,3,5,11,22,33,55";
$params = extract_args('title="chart1" size="400x400" xaxis="things xways" yaxis="Vertical things" format="pie" legends="a,b,c,d,e,f,g,h"');
$out = $obj->process( 'chart', $content, $params, $TEST_DIR );
ok( has_file($out), 'chart created a file' );

# sparkline
$content = '1,4,5,20,4,5,3,1';
$obj     = App::Basis::ConvertText2::Plugin::Sparkline->new();
$params  = extract_args("title='sparkline' scheme='blue'");
$out     = $obj->process( 'sparkline', $content, $params, $TEST_DIR );
ok( has_file($out), 'sparkline created a file' );

# venn
$content = 'abel edward momo albert jack julien chris
edward isabel antonio delta albert kevin jake
gerald jake kevin lucia john edward';
$obj    = App::Basis::ConvertText2::Plugin::Venn->new();
$params = extract_args("title='sample venn diagram' legends='team1 team2 team3' scheme='rgb' explain='1'");
$out    = $obj->process( 'sparkline', $content, $params, $TEST_DIR );
ok( has_file($out), 'venn created a file' );

# links
$obj     = App::Basis::ConvertText2::Plugin::Text->new();
$content = "pandoc    | http://johnmacfarlane.net/pandoc
    PrinceXML | http://www.princexml.com
    markdown  | http://daringfireball.net/projects/markdown
    msc       | http://www.mcternan.me.uk/mscgen/
    ditaa     | http://ditaa.sourceforge.net
    PlantUML  | http://plantuml.sourceforge.net
    See Salt  | http://plantuml.sourceforge.net/salt.html
    graphviz  | http://graphviz.org
    JSON      | https://en.wikipedia.org/wiki/Json
    YAML      | https://en.wikipedia.org/wiki/Yaml
";
$params = undef;
$out = $obj->process( 'links', $content, $params, $TEST_DIR );
ok( $out && $out =~ /<ul/, 'links created some content' );

# yamlasjson
$content = 'epg:
  - triplet: [1,2,3,7]
    channel: BBC3
    date: 2013-10-20
    time: 20:30
    crid: dvb://112.4a2.5ec;2d22~20131020T2030000Z—PT01H30M
  - triplet: [1,2,3,9]
    channel: BBC4
    date: 2013-11-20
    time: 21:00
    crid: dvb://112.4a2.5ec;2d22~20131120T2100000Z—PT01H30M
';

# page
$params = undef;
$obj    = App::Basis::ConvertText2::Plugin::Text->new();
$out    = $obj->process( 'yamlasjson', $content, $params, $TEST_DIR );
ok( $out && $out =~ /~~~~\{\.json/, 'yamlasjson created some content' );

# table
$content = 'apples,bananas,cake,cabbage,edam,fromage,tomatoes,chips
1,2,3,5,11,22,33,55
1,2,3,5,11,22,33,55
1,2,3,5,11,22,33,55
1,2,3,5,11,22,33,55';
$params = undef;
$obj    = App::Basis::ConvertText2::Plugin::Text->new();
$out    = $obj->process( 'table', $content, $params, $TEST_DIR );
ok( $out && $out =~ /<table.*?>\s?<tr><td>apples/sm, 'table created' );

# version
$content = '0.1 2014-04-12
  * removed ConvertFile.pm
  * using Path::Tiny rather than other things
  * changed to use pandoc fences ~~~~{.tag} rather than xml format <tag>
0.006 2014-04-10
  * first release to github
';
$params = undef;
$obj    = App::Basis::ConvertText2::Plugin::Text->new();
$out    = $obj->process( 'version', $content, $params, $TEST_DIR );
ok( $out && $out =~ /<table.*?>\s?<tr><th.*?>Version/sm && $out =~ m|<tr><td.*?>0\.1</td><td.*?>2014?|sm, 'version created a table' );

SKIP: {
    if ( $ENV{AUTHOR_TESTING} ) {

        # ditaa
        $content = 'Full example
+--------+   +-------+    +-------+
|        | --+ ditaa +--> |       |
|  Text  |   +-------+    |diagram|
|Document|   |!magic!|    |       |
|     {d}|   |       |    |       |
+---+----+   +-------+    +-------+
    :                         ^
    |       Lots of work      |
    \-------------------------+
~~~~';
        $obj    = App::Basis::ConvertText2::Plugin::Ditaa->new();
        $params = undef;
        $out    = $obj->process( 'ditaa', $content, $params, $TEST_DIR );
        ok( has_file($out), 'ditaa created a file' );

        # graphviz
        $content = 'graph G {
    run -- intr;
    intr -- runbl;
    runbl -- run;
    run -- kernel;
    kernel -- zombie;
    kernel -- sleep;
    kernel -- runmem;
    sleep -- swap;
    swap -- runswap;
    runswap -- new;
    runswap -- runmem;
    new -- runmem;
    sleep -- runmem;
}
';
        $obj    = App::Basis::ConvertText2::Plugin::Graphviz->new();
        $params = undef;
        $out    = $obj->process( 'graphviz', $content, $params, $TEST_DIR );
        ok( has_file($out), 'graphviz created a file' );

        # mscgen
        $content = '# Fictional client-server protocol
msc {
 arcgradient = 8;

 a [label="Client"],b [label="Server"];

 a=>b [label="data1"];
 a-xb [label="data2"];
 a=>b [label="data3"];
 a<=b [label="ack1, nack2"];
 a=>b [label="data2", arcskip="1"];
 |||;
 a<=b [label="ack3"];
 |||;
}
';
        $obj    = App::Basis::ConvertText2::Plugin::Mscgen->new();
        $params = undef;
        $out    = $obj->process( 'mscgen', $content, $params, $TEST_DIR );
        ok( has_file($out), 'mscgen created a file' );

        # uml
        $content = "'start/enduml tags are optional
\@startuml
skinparam backgroundcolor AntiqueWhite
left to right direction
skinparam packageStyle rect
actor customer
actor clerk
rectangle checkout {
  customer -- (checkout)
  (checkout) .> (payment) : include
  (help) .> (checkout) : extends
  (checkout) -- clerk
}
\@enduml";
        $obj    = App::Basis::ConvertText2::Plugin::Uml->new();
        $params = undef;
        $out    = $obj->process( 'uml', $content, $params, $TEST_DIR );
        ok( has_file($out), 'uml created a file' );

        # gle
        $content = 'size 10 9
set font texcmr hei 0.5 just tc

begin letz
   data "saddle.z"
   z = 3/2*(cos(3/5*(y-1))+5/4)/(1+(((x-4)/3)^2))
   x from 0 to 20 step 0.5
   y from 0 to 20 step 0.5
end letz

amove pagewidth()/2 pageheight()-0.1
write "Saddle Plot (3D)"

begin object saddle
   begin surface
      size 10 9
      data "saddle.z"
      xtitle "X-axis" hei 0.35 dist 0.7
      ytitle "Y-axis" hei 0.35 dist 0.7
      ztitle "Z-axis" hei 0.35 dist 0.9
      top color blue
      zaxis ticklen 0.1 min 0 hei 0.25
      xaxis hei 0.25 dticks 4 nolast nofirst
      yaxis hei 0.25 dticks 4
   end surface
end object

amove pagewidth()/2 0.2
draw "saddle.bc"
';
        $obj    = App::Basis::ConvertText2::Plugin::Gle->new();
        $params = undef;
        $out    = $obj->process( 'gle', $content, $params, $TEST_DIR );
        ok( has_file($out), 'gle created a file' );

# gle
        $content = '#
# $Id: surface1.dem,v 1.11 2004/09/17 05:01:12 sfeam Exp $
#
set term png size 600, 400
set output "/tmp/saddle.png"
set samples 21
set isosample 11
set xlabel "X axis" offset -3,-2
set ylabel "Y axis" offset 3,-2
set zlabel "Z axis" offset -5
set title "3D gnuplot demo"
set label 1 "This is the surface boundary" at -10,-5,150 center
set arrow 1 from -10,-5,120 to -10,0,0 nohead
set arrow 2 from -10,-5,120 to 10,0,0 nohead
set arrow 3 from -10,-5,120 to 0,10,0 nohead
set arrow 4 from -10,-5,120 to 0,-10,0 nohead
set xrange [-10:10]
set yrange [-10:10]
splot x*y
';
        $obj    = App::Basis::ConvertText2::Plugin::Gnuplot->new();
        $params = undef;
        $out    = $obj->process( 'gnuplot', $content, $params, $TEST_DIR );
        ok( has_file($out), 'gnuplot created a file' );

    }
    else {
        skip "Author testing programs", 6;

    }
}

path($TEST_DIR)->remove_tree;

# -----------------------------------------------------------------------------
# completed all the tests
