use DBI;
use DBD::Chart;
use strict;

$ARGV[0] = 0 unless ($ARGV[0]);
my $i;

my $dbh = DBI->connect('dbi:Chart:', undef, undef,
{
	PrintError => 1,
	RaiseError => 0
}) || die 'Can\'t connect';

open(MAP, '>testres.html');
print MAP '<html><body>
<h1>Lots more DBD::Chart examples...</h1>
<p>
This page and the associated images were rendered
using the script in <a href="http://www.presicient.com/dbdchart/test.zip">test.zip</a>.
<p>
Move your mouse over the various plot elements to see the imagemap effect.
Note that the mapped URLs don\'t exist.
';
#
#	iconic barchart
#
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @pumpsales = (123, 100, 78, 45, 50, 70, 30, 36, 67, 234, 201, 194);
my @turksales = (123, 70, 65, 35, 40, 70, 90, 80, 67, 134, 301, 250);
$dbh->do('CREATE TABLE iconic (month char(3), pumpkins integer, turkeys integer)');
my $sth = $dbh->prepare('INSERT INTO iconic VALUES(?, ?, ?)');
for (my $i = 0; $i <= $#months; $i++) {
	$sth->execute($months[$i], $pumpsales[$i], $turksales[$i]);
}
$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM iconic
WHERE WIDTH=820 and HEIGHT=500 AND
	title = 'Monthly Pumpkin vs. Turkey Sales' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X-AXIS = 'Month' AND
	Y-AXIS = 'Sales' AND
	icons = ('pumpkin.png', 'turkey.png' ) AND
	keepOrigin = 1 AND
	SHOWGRID = 1 AND
	X-ORIENT = 'HORIZONTAL' AND
	MAPNAME = 'pumpkins' AND
	MAPURL = 'http://www.presicient.com/samplemap.pl'"	);

$sth->execute;
my $row = $sth->fetchrow_arrayref;

open(BAR, '>iconbar.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Iconic Barchart with Imagemap</h2>', "\n";
print MAP '<img src=iconbar.png usemap="#pumpkins">',
	$$row[1], "\n";
$dbh->do('DROP TABLE iconic');
print "iconic barchart OK\n";
#
#	simple barchart with imagemap
#
$dbh->do('CREATE TABLE barchart (segment varchar(10), value smallint)');
$sth = $dbh->prepare('INSERT INTO barchart VALUES(?, ?)');
my @x = qw(first second third fourth fifth sixth);
my @y = (10, 20, 30, 40, 50, 60);
for ($i = 0; $i <= $#x; $i++) {
	$sth->execute($x[$i], $y[$i]);
}
$sth= $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM BARCHART
WHERE WIDTH=600 AND HEIGHT=600 AND
	title = 'Sample Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X-AXIS = 'X Axis' AND
	Y-AXIS = 'Y Axis' AND
	keepOrigin = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, green, blue, yellow, cyan) AND
	X-ORIENT = 'HORIZONTAL' AND
	MAPNAME = 'barsample' AND
	MAPURL = 'http://www.presicient.com/samplemap.pl?x=:X&y=:Y' AND
	MAPTYPE = 'HTML' AND
	MAPSCRIPT = 'ONCLICK=\"alert(''Got X=:X, Y=:Y'')\"'"
	) || warn $dbh->errstr, "\n";

$sth->execute || warn $sth->errstr, "\n";
$row = $sth->fetchrow_arrayref;

open(BAR, '>samplebar.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Simple Barchart with Imagemap</h2>
<b>Note: Click on the bars to see the MAPSCRIPT attribute results.</b><p>
';
print MAP '<img src=samplebar.png usemap="#barsample">',
	$$row[1], "\n";
$dbh->do('DROP TABLE barchart');
print "simple barchart OK\n";
#
#	simple boxchart with imagemap
#
@x = ();
@y = ();
$dbh->do('CREATE TABLE samplebox (First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO samplebox VALUES(?, ?)');
foreach (1..100) { 
	$sth->execute($_, int($_/2)+20);
}
$sth = $dbh->prepare("SELECT BOXCHART, IMAGEMAP FROM samplebox
WHERE WIDTH=500 and HEIGHT=300 AND
	title = 'Sample Box & Whisker Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	MAPNAME = 'boxsample' AND
	SHOWVALUES = 1 AND
	COLORS=(red, blue) AND
	mapURL = 'http://www.presicient.com/samplemap.pl?plotnum=:PLOTNUM&x=:X&y=:Y&z=:Z'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(PIE, '>samplebox.png');
binmode PIE;
print PIE $$row[0];
close PIE;
print MAP '<h2>Boxchart with Imagemap</h2>', "\n";
print MAP '<img src=samplebox.png usemap="#boxsample">',
	$$row[1], "\n";
$dbh->do('DROP TABLE samplebox');
print "boxchart OK\n";
#
#	3-axis barchart
#
@months = ();
my @regions = ();
my @sales = ();
my $sign = 1;
$dbh->do('CREATE TABLE threeaxis (Month char(3), Sales integer, Region varchar(10))');
$sth = $dbh->prepare('INSERT INTO threeaxis VALUES(?, ?, ?)');
foreach my $mo qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec) {
	foreach my $dis qw(East South Midwest West Northwest) {
		$sth->execute($mo, $sign * int(rand(12345)), $dis);
#		$sign *= -1 if ($mo=~/^[JA]/);
	}
}
$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threeaxis
WHERE WIDTH=700 AND HEIGHT=600 AND
	title = 'Monthly Sales by Region' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	x-AXIS = 'Month' AND
	y-AXIS = 'Sales' AND
	z-AXIS = 'Region' AND
	SHOWGRID = 1 AND
	MAPNAME = 'sales_by_region' AND
	mapURL = 'http://www.presicient.com/samplemap.pl?month=:X&sales=:Y&region=:Z'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>bar3axis.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>3-Axis Barchart with Imagemap</h2>', "\n";
print MAP '<img src=bar3axis.png usemap="#sales_by_region">',
	$$row[1], "\n";
$dbh->do('DROP table threeaxis');
print "3 Axis barchart OK\n";
#
#	multrange 3D barchart with imagemap
#
@x = qw(first second third fourth fifth sixth);
@y = (10, 20, -30, 40, 50, 60);
my @yhi = (50, 30, 80, 75, 120, 70);
$dbh->do('CREATE TABLE threedbar (Segment varchar(10), First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?)');
for ($i = 0; $i <= $#x; $i++) {
	$sth->execute($x[$i], $y[$i], $yhi[$i]);
}
$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar
WHERE WIDTH=400 AND HEIGHT=400 AND
	title = 'Sample 3-D Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X-AXIS = 'X Axis' AND
	Y-AXIS = 'Y Axis' AND
	3-D = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	MAPNAME = 'bars3dsample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samp3dbar.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Multirange 3-D Barchart with Imagemap</h2>', "\n";
print MAP '<img src=samp3dbar.png usemap="#bars3dsample">',
	$$row[1], "\n";
$dbh->do('DROP table threedbar');
print "3-D barchart OK\n";
#
#	simple piechart with imagemap
#
$dbh->do('CREATE TABLE samplepie (Segment varchar(10), First integer)');
$sth = $dbh->prepare('INSERT INTO samplepie VALUES(?, ?)');
for ($i = 0; $i <= $#x; $i++) {
	$sth->execute($x[$i], $yhi[$i]);
}
$sth = $dbh->prepare("SELECT PIECHART, IMAGEMAP FROM samplepie
WHERE WIDTH=500 AND HEIGHT=500 AND
	title = 'Sample Pie Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	3-D=1 AND
	MAPNAME = 'piesample' AND
	COLORS=(red, green, blue, yellow, gray, marine) AND
	mapURL = 'http://www.presicient.com/samplemap.pl?x=:X&y=:Y&z=:Z'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(PIE, '>samplepie.png');
binmode PIE;
print PIE $$row[0];
close PIE;
print MAP '<h2>Piechart with Imagemap</h2>', "\n";
print MAP '<img src=samplepie.png usemap="#piesample">',
	$$row[1], "\n";
$dbh->do('DROP table samplepie');
print "piechart OK\n";
#
#	simple candlestick with imagemap
#
$dbh->do('CREATE TABLE samplechart (Segment varchar(10), Low integer, High integer)');
$sth = $dbh->prepare('INSERT INTO samplechart VALUES(?, ?, ?)');
for ($i = 0; $i <= $#x; $i++) {
	$sth->execute($x[$i], $y[$i], $yhi[$i]);
}
$sth = $dbh->prepare("SELECT CANDLESTICK, IMAGEMAP FROM samplechart
WHERE WIDTH=300 AND HEIGHT=300 AND
	title = 'Sample Candlestick Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	x-AXIS = 'Month' AND
	y-AXIS = 'Price' AND
	COLOR=red AND SHAPE=filldiamond AND
	MAPNAME = 'candlesample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl?x=:X&y=:Y&z=:Z'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>sampcandle.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Candlestick with Imagemap</h2>', "\n";
print MAP '<img src=sampcandle.png usemap="#candlesample">',
	$$row[1], "\n";
print "candlestick OK\n";
#
#	multidomain linegraph with imagemap
#
$sth = $dbh->prepare("SELECT LINEGRAPH, IMAGEMAP FROM samplechart
WHERE WIDTH=300 AND HEIGHT=300 AND
	title = 'Multirange Linegraph' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	x-AXIS = 'Month' AND
	y-AXIS = 'Price' AND
	X-ORIENT = 'VERTICAL' AND
	keepOrigin = 1 AND
	showValues = 1 AND
	logo = 'gowilogo.png' AND
	MAPNAME = 'linesample' AND
	SHOWGRID=1 AND TEXTCOLOR=green AND GRIDCOLOR=blue AND
	COLORS=(red, blue) AND SHAPES=(filldiamond, fillcircle) AND
	mapURL = 'http://www.presicient.com/samplemap.pl?plotnum=:PLOTNUM&x=:X&y=:Y'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samplines.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Multirange Linegraph with Imagemap</h2>', "\n";
print MAP '<img src=samplines.png usemap="#linesample">',
	$$row[1], "\n";
print "multirange linegraph OK\n";
#
#	multidomain pointgraph with imagemap
#
$sth = $dbh->prepare("SELECT POINTGRAPH, IMAGEMAP FROM samplechart
WHERE WIDTH=300 AND HEIGHT=300 AND
	title = 'Multirange Pointgraph' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	x-AXIS = 'Segment' AND
	y-AXIS = 'Price' AND
	X-ORIENT = 'VERTICAL' AND
	keepOrigin = 1 AND
	icons = ('pumpkin.png') AND
	MAPNAME = 'pointsample' AND
	COLORS=(red, blue) AND SHAPES=(filldiamond, icon) AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samppoints.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Multirange Pointgraph with Imagemap</h2>', "\n";
print MAP '<img src=samppoints.png usemap="#pointsample">',
	$$row[1], "\n";
print "multirange pointgraph OK\n";
#
#	multirange areagraph with imagemap
#
my @y2 = (5, -10, 15, -20, 25, 30);
$sth = $dbh->prepare('UPDATE samplechart SET High=? WHERE Segment=?');
for ($i = 0; $i <= $#x; $i++) {
	$sth->execute($y2[$i], $x[$i]);
}
$sth = $dbh->prepare("SELECT AREAGRAPH, IMAGEMAP FROM samplechart
WHERE WIDTH=300 AND HEIGHT=300 AND
	title = 'Multirange Areagraph' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	x-AXIS = 'Segment' AND
	y-AXIS = 'Price' AND
	X-ORIENT = 'VERTICAL' AND
	keepOrigin = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	MAPNAME = 'areasample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);

$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samparea.png');
binmode BAR;
print BAR $$row[0];
close BAR;
print MAP '<p><h2>Multirange Areagraph with Imagemap</h2>', "\n";
print MAP '<img src=samparea.png usemap="#areasample">',
	$$row[1], "\n";

print MAP '</body></html>';
close MAP;
print "multirange areagraph OK\n";

$dbh->disconnect;

