use DBI;

$dbh = DBI->connect('dbi:Chart:', undef, undef);

open(MAP, ">bar3d.html");
print MAP '<html><body>
<img src=samp3dbar.png>
<img src=samp3dbar2.png>
<img src=samp3dbar3.png>
<img src=samp3dbar4.png>
<img src=samp3dbar5.png>
</body></html>';
close MAP;
#
#	multrange 3D barchart with imagemap
#
@x = qw(first second third fourth fifth sixth seventh eighth ninth tenth eleventh twelfth);
@y = (10, 20, -30, 40, 50, 60, 80, 100, 120, 40, 90, 75);
my @yhi = (50, 30, 80, 75, 120, 70, 32, 78, 104, 99, 103, 19);

$dbh->do('CREATE TABLE threedbar (Segment varchar(10), First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?)');
$sth->execute($x[0], $y[0], $yhi[0]);

$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar
WHERE WIDTH=400 AND HEIGHT=400 AND
	title = 'Sample THREE_D Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X_AXIS = 'X Axis' AND
	Y_AXIS = 'Y Axis' AND
	THREE_D = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	SHOWVALUES=1 AND
	MAPNAME = 'bars3dsample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samp3dbar5.png');
binmode BAR;
print BAR $$row[0];
close BAR;
$dbh->do('DROP table threedbar');
print "THREE_D barchart OK\n";

$dbh->do('CREATE TABLE threedbar (Segment varchar(10), First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?)');

$sth->execute($x[$_], $y[$_], $yhi[$_])
	foreach (0..$#x);

$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar
WHERE WIDTH=400 AND HEIGHT=400 AND
	title = 'Sample THREE_D Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X_AXIS = 'X Axis' AND
	Y_AXIS = 'Y Axis' AND
	THREE_D = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	SHOWVALUES=1 AND
	MAPNAME = 'bars3dsample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samp3dbar.png');
binmode BAR;
print BAR $$row[0];
close BAR;
#print MAP '<p><h2>Multirange THREE_D Barchart with Imagemap</h2>', "\n";
#print MAP '<img src=samp3dbar.png usemap="#bars3dsample">',
#	$$row[1], "\n";
$dbh->do('DROP table threedbar');
print "THREE_D barchart OK\n";

$dbh->do('CREATE TABLE threedbar (Segment varchar(10), First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?)');
$sth->execute($x[$_], $y[$_], $yhi[$_])
	foreach (0..1);

$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar
WHERE WIDTH=400 AND HEIGHT=400 AND
	title = 'Sample THREE_D Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X_AXIS = 'X Axis' AND
	Y_AXIS = 'Y Axis' AND
	THREE_D = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	SHOWVALUES=1 AND
	MAPNAME = 'bars3dsample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samp3dbar2.png');
binmode BAR;
print BAR $$row[0];
close BAR;
#print MAP '<p><h2>Multirange THREE_D Barchart with Imagemap</h2>', "\n";
#print MAP '<img src=samp3dbar.png usemap="#bars3dsample">',
#	$$row[1], "\n";
$dbh->do('DROP table threedbar');
print "THREE_D barchart OK\n";

$dbh->do('CREATE TABLE threedbar (Segment varchar(10), First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?)');
$sth->execute($x[$_], $y[$_], $yhi[$_])
	foreach (0..2);

$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar
WHERE WIDTH=400 AND HEIGHT=400 AND
	title = 'Sample THREE_D Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X_AXIS = 'X Axis' AND
	Y_AXIS = 'Y Axis' AND
	THREE_D = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	SHOWVALUES=1 AND
	MAPNAME = 'bars3dsample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samp3dbar3.png');
binmode BAR;
print BAR $$row[0];
close BAR;
$dbh->do('DROP table threedbar');
print "THREE_D barchart OK\n";

$dbh->do('CREATE TABLE threedbar (Segment varchar(10), First integer, Second integer)');
$sth = $dbh->prepare('INSERT INTO threedbar VALUES(?, ?, ?)');
$sth->execute($x[$_], $y[$_], $yhi[$_])
	foreach (0..3);

$sth = $dbh->prepare("SELECT BARCHART, IMAGEMAP FROM threedbar
WHERE WIDTH=400 AND HEIGHT=400 AND
	title = 'Sample THREE_D Bar Chart' AND
	signature = 'Copyright(C) 2001, Presicient Corp.' AND
	X_AXIS = 'X Axis' AND
	Y_AXIS = 'Y Axis' AND
	THREE_D = 1 AND
	SHOWGRID = 1 AND
	COLORS=(red, blue) AND
	SHOWVALUES=1 AND
	MAPNAME = 'bars3dsample' AND
	mapURL = 'http://www.presicient.com/samplemap.pl'"
	);
$sth->execute;
$row = $sth->fetchrow_arrayref;

open(BAR, '>samp3dbar4.png');
binmode BAR;
print BAR $$row[0];
close BAR;
$dbh->do('DROP table threedbar');
print "THREE_D barchart OK\n";

