use DBI;
use DBD::Chart;

$|=1;
$^W=1;

BEGIN { $tests = 45 }

print "1..$tests\n";

use constant PI => 3.1415926;

$dbh = DBI->connect('dbi:Chart:');

$dbh->do("update colormap set redvalue=255, greenvalue=0, bluevalue=0
where name='red'");
$dbh->do("update colormap set redvalue=0, greenvalue=0, bluevalue=255
where name='blue'");
$dbh->do("insert into colormap values('newcolor', 124, 37, 97)");

my @x = ( 10, 20, 30, 40, 50);
my @y1 = ( 23, -39, 102, 67, 80);
my @y2 = ( 53, 39, 127, 89, 108);
my @y3 = ( 35, 45, 55, 65, 75);
my @xtmstamp = ( '2002-12-24 10:33:00', '2002-12-24 13:33:06', 
	'2002-12-24 17:20:00', '2002-12-25 00:13:34', '2002-12-25 04:44:44');
my @xdate = ( '2002-12-24', '2002-12-25', '2002-12-26', '2002-12-27', '2002-12-28');
my @ytime = ( '0:12:34', '11:29:00', '5:57:33', '22:22:22', '4:06:01');
my @xdate2 = ( '1970-01-24', '1975-01-25', '1985-01-26', '1997-01-27', '2030-01-28');
my @ytime2 = ( '0:12:34', '11:29:00', '255:57:33', '2222:22:22', '4328:06:01');
my @xbox = ();
my @xfreq = ();
my @yfreq = ();
my %xbhash = ();
my @z = qw (Q1 Q2 Q3 Q4 Q1 Q2 Q3 Q4 Q1 Q2 Q3 Q4 Q1 Q2 Q3 Q4);
my @x3d = qw(North North North North 
East East East East South South South South West West West West);
my @y3d = (
	123, 354, 987, 455,
	346, 978, 294, 777,
	765, 99,  222, 409,
	687, 233, 555, 650);

open(HTMLF, ">t/plottest.html");
print HTMLF "<html><body>
<img border=0 src=simpline.png alt='simpline' usemap=#simpline><p>
<img border=0 src=simpscat.png alt='simpscat' usemap=#simpscat><p>
<img border=0 src=simparea.png alt='simparea' usemap=#simparea><p>
<img border=0 src=symline.png alt='symline' usemap=#symline><p>
<img border=0 src=simpbar.png alt='simpbar' usemap=#simpbar><p>
<img border=0 src=iconbars.png alt='iconbars' usemap=#iconbars><p>
<img border=0 src=iconhisto.png alt='iconhisto' usemap=#iconhisto><p>
<img border=0 src=simpbox.png alt='simpbox' usemap=#simpbox><p>
<img border=0 src=simpcandle.png alt='simpcandle' usemap=#simpcandle><p>
<img border=0 src=simppie.png alt='simppie' usemap=#simppie><p>
<img border=0 src=pie3d.png alt='pie3d' usemap=#pie3d><p>
<img border=0 src=bar3d.png alt='bar3d' usemap=#bar3d><p>
<img border=0 src=bar3axis.png alt='bar3axis' usemap=#bar3axis><p>
<img border=0 src=simphisto.png alt='simphisto' usemap=#simphisto><p>
<img border=0 src=histo3d.png alt='histo3d' usemap=#histo3d><p>
<img border=0 src=histo3axis.png alt='histo3axis' usemap=#histo3axis><p>
<img border=0 src=templine.png alt='templine' usemap=#templine><p>
<img border=0 src=templine2.png alt='templine2' usemap=#templine2><p>
<img border=0 src=logtempline.png alt='logtempline' usemap=#logtempline><p>
<img border=0 src=tempbar.png alt='tempbar' usemap=#tempbar><p>
<img border=0 src=temphisto.png alt='temphisto' usemap=#temphisto><p>
<img border=0 src=complinept.png alt='complinept' usemap=#complinept><p>
<img border=0 src=complpa.png alt='complpa' usemap=#complpa><p>
<img border=0 src=compblpa.png alt='compblpa' usemap=#compblpa><p>
<img border=0 src=complnbox.png alt='complnbox' usemap=#complnbox><p>
<img border=0 src=compllbb.png alt='compllbb' usemap=#compllbb><p>
<img border=0 src=comphisto.png alt='comphisto' usemap=#comphisto><p>
<img border=0 src=compbars.png alt='compbars' usemap=#compbars><p>
<img border=0 src=denseline.png alt='denseline'><p>
<img border=0 src=densearea.png alt='densearea'><p>
<img border=0 src=simpgantt.png alt='simpgantt' usemap=#simpgantt><p>
<img border=0 src=stackbar.png alt='stackbar' usemap=#stackbar><p>
<img border=0 src=stackicon.png alt='stackicon' usemap=#stackicon><p>
<img border=0 src=stackarea.png alt='stackarea' usemap=#stackarea><p>
<img border=0 src=stackhisto.png alt='stackhisto' usemap=#stackhisto><p>
<img border=0 src=stackcandle.png alt='stackcandle' usemap=#stackcandle><p>
<img border=0 src=multilinemm.png alt='multilinemm' usemap=#multilinemm><p>
<img border=0 src=quadtree.png alt='quadtree' usemap=#quadtree><p>
<img border=0 src=stack3Dbar.png alt='stack3Dbar' usemap=#stack3Dbar><p>
<img border=0 src=stack3Dhisto.png alt='stack3Dhisto' usemap=#stack3Dhisto><p>
<img border=0 src=tmstamp.png alt='tmstamp' usemap=#tmstamp><p>
<img border=0 src=floatarea.png alt='floatarea' usemap=#floatarea><p>
<img border=0 src=floathisto.png alt='floathisto' usemap=#floathisto><p>
<img border=0 src=floatbar.png alt='floatbar' usemap=#floatbar><p>
<img border=0 src=multwidth.png alt='multwidth' usemap=#multwidth><p>
";

foreach (1..100) {
	push @xbox, int(rand(51)+10);
	$xbhash{$xbox[$#xbox]} += 1, next
		if $xbhash{$xbox[$#xbox]};
	$xbhash{$xbox[$#xbox]} = 1;
}

push(@xfreq, $_),
push (@yfreq, $xbhash{$_} ? $xbhash{$_} : 0)
	foreach (10..60);

my @xfreq2 = ();
my @yfreq2 = ();
my @xbox2 = ();
my %xbhash2 = ();
foreach (1..200) {
	push @xbox2, int(rand(61)+10);
	$xbhash2{$xbox2[$#xbox2]} += 1, next
		if $xbhash2{$xbox2[$#xbox2]};
	$xbhash2{$xbox2[$#xbox2]} = 1;
}

push(@xfreq2, $_),
push (@yfreq2, $xbhash2{$_} ? $xbhash2{$_} : 0)
	foreach (10..70);
my $testnum = 0;
goto $ARGV[0] if ($ARGV[0]);
	$dbh->do('create table simpline (x integer, y integer)');
	$sth = $dbh->prepare('insert into simpline values(?, ?)');
	$sth->execute($x[$_], $y1[$_])
		foreach (0..$#x);
#
#	simple scatter chart
#
simpscat:
	$sth = $dbh->prepare("select pointgraph, imagemap from simpline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Scattergraph Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	LOGO='t/gowilogo.png' AND FORMAT='PNG' AND SHOWGRID=0 AND
	MAPNAME='simpscat' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND SHOWVALUES=1");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simpscat');
	$testnum++;
	print "ok $testnum simpscat OK\n";
#
#	simple line chart
#
simpline:
	$sth = $dbh->prepare("select linegraph, imagemap from simpline
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND	TITLE='Linegraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND	LOGO='t/gowilogo.png' 
	AND FORMAT='PNG' 
	AND SHOWGRID=1 
	AND	LINEWIDTH=4 
	AND FONT='D:\\WINNT\\Fonts\\antquab.ttf'
	AND SHOWVALUES=8
	AND	MAPNAME='simpline' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLOR='newcolor'
	AND SHAPE='fillcircle'
	AND BORDER=0
	AND SHOWVALUES=1");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simpline');
	$testnum++;
	print "ok $testnum simpline OK\n";
#
#	simple area chart
#
simparea:
	$sth = $dbh->prepare("select areagraph, imagemap from simpline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Areagraph Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	LOGO='t/gowilogo.png' AND FORMAT='PNG' AND SHOWGRID=1 AND
	MAPNAME='simparea' AND COLOR='newcolor' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND BORDER=0
	AND MAPTYPE='HTML' AND SHOWVALUES=0");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simparea');
	$testnum++;
	print "ok $testnum simparea OK\n";
#
#	simple linechart w/ sym domain and icons
#
symline:
	$dbh->do('create table symline (xdate varchar(20), y integer)');
	$sth = $dbh->prepare('insert into symline values(?, ?)');
	$sth->execute($xdate[$_], $y1[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select linegraph, imagemap from symline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Symbolic Domain Linegraph Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	LOGO='t/gowilogo.png' AND FORMAT='PNG' AND SHOWGRID=1 AND
	MAPNAME='symline' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLOR=newcolor AND SHAPE=fillcircle");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'symline');
	$testnum++;
	print "ok $testnum symline OK\n";
#
#	simple bar chart
#
simpbar:
	$sth = $dbh->prepare("select barchart, imagemap from symline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND
	MAPNAME='simpbar' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLOR=newcolor");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simpbar');
	$testnum++;
	print "ok $testnum simpbar OK\n";
#
#	simple bar chart w/ icons
#
iconbars:
	$sth = $dbh->prepare("select barchart, imagemap from symline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Iconic Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND ICON='t/pumpkin.png' AND
	MAPNAME='iconbars' AND SHOWGRID=1 AND GRIDCOLOR='blue' AND
	TEXTCOLOR='dbrown' AND
	MAPSCRIPT='ONCLICK=\"alert(''Got X=:X, Y=:Y'')\"' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'iconbars');
	$testnum++;
	print "ok $testnum iconbars OK\n";
#
#	simple bar chart w/ icons
#
iconhisto:
	$sth = $dbh->prepare("select histogram, imagemap from symline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and 
	Y_AXIS='Some Range' AND
	TITLE='Iconic Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND ICON='t/pumpkin.png' AND
	MAPNAME='iconhisto' AND SHOWGRID=1 AND GRIDCOLOR='red' AND
	TEXTCOLOR='newcolor' AND
	MAPSCRIPT='ONCLICK=\"alert(''Got X=:X, Y=:Y'')\"' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'iconhisto');
	$testnum++;
	print "ok $testnum iconhisto OK\n";
#
#	simple boxchart
#
simpbox:
	$dbh->do('create table simpbox (xbox integer, xbox2 integer)');
	$sth = $dbh->prepare('insert into simpbox values(?, ?)');

	$sth->execute($xbox[$_], $xbox2[$_])
		foreach (0..$#xbox);

	$sth = $dbh->prepare("select boxchart, imagemap from simpbox
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	TITLE='Boxchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('newcolor', 'red') AND SHOWVALUES=1 AND
	MAPNAME='simpbox' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simpbox');
	$testnum++;
	print "ok $testnum simpbox OK\n";
#
#	simple candlestick
#
simpcandle:
	$dbh->do('create table simpcandle (x integer, ylo integer, yhi integer)');
	$sth = $dbh->prepare('insert into simpcandle values(?, ?, ?)');
	$sth->execute($x[$_], $y1[$_], $y2[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select candlestick, imagemap from simpcandle
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	Y_AXIS = 'Price' AND
	TITLE='Candlestick Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('newcolor') AND SHAPE='fillsquare' AND
	SHOWVALUES=1 AND SHOWGRID=1 AND
	MAPNAME='simpcandle' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simpcandle');
	$testnum++;
	print "ok $testnum simpcandle OK\n";
#
#	simple pie chart
#
simppie:
	$dbh->do('create table simppie (x integer, y2 integer)');
	$sth = $dbh->prepare('insert into simppie values(?, ?)');
	$sth->execute($x[$_], $y2[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select piechart, imagemap from simppie
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	TITLE='Piechart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('red', 'blue', 'newcolor', 'green', 'yellow') AND
	MAPNAME='simppie' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simppie');
	$testnum++;
	print "ok $testnum simppie OK\n";
#
#	3-D pie chart
#
pie3d:
	$sth = $dbh->prepare("select piechart, imagemap from simppie
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	TITLE='3-D Piechart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('red', 'blue', 'newcolor', 'green', 'yellow') AND
	THREE_D=1 AND
	MAPNAME='pie3d' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'pie3d');
	$testnum++;
	print "ok $testnum pie3d OK\n";
#
#	simple histogram
#
simphisto:
	$sth = $dbh->prepare("select histogram, imagemap from simppie
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLOR IN ('red', 'green', 'orange', 'blue', 'newcolor') AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='simphisto' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simphisto');
	$testnum++;
	print "ok $testnum simphisto OK\n";
#
#	linechart w/ temporal domain
#
templine:
	$dbh->do('create table templine (xdate date, y integer)');
	$sth = $dbh->prepare('insert into templine values(?, ?)');
	$sth->execute($xdate[$_], $y1[$_])
		foreach (0..$#xdate);
	$sth = $dbh->prepare("select linegraph, imagemap from templine
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Domain Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	X_ORIENT='VERTICAL' AND LOGO='t/gowilogo.png' AND
	FORMAT='PNG' AND COLORS=newcolor AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='templine' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'templine');
	$testnum++;
	print "ok $testnum templine OK\n";
#
#	linechart w/ temporal domain and range
#
templine2:
	$dbh->do('create table templine2 (xdate date, y interval)');
	$sth = $dbh->prepare('insert into templine2 values(?, ?)');
	$sth->execute($xdate[$_], $ytime[$_])
		foreach (0..$#xdate);

	$sth = $dbh->prepare("select linegraph, imagemap from templine2
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Range Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	X_ORIENT='VERTICAL' AND LOGO='t/gowilogo.png' AND
	FORMAT='PNG' AND COLORS=newcolor AND
	SHOWGRID=1 AND SHOWVALUES=1 AND SHAPE=fillcircle AND
	MAPNAME='templine2' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'templine2');
	$testnum++;
	print "ok $testnum templine2 OK\n";
#
#	log linechart w/ temporal domain and range
#
logtempline:
	$dbh->do('create table logtempline (xdate date, y interval)');
	$sth = $dbh->prepare('insert into logtempline values(?, ?)');
	$sth->execute($xdate2[$_], $ytime2[$_])
		foreach (0..$#xdate2);

	$sth = $dbh->prepare("select linegraph, imagemap from logtempline
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Logarithmic Temporal Range Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	X_ORIENT='VERTICAL' AND Y-LOG=1 AND
	FORMAT='PNG' AND COLORS=newcolor AND
	SHOWGRID=1 AND SHOWVALUES=1 AND SHAPE=fillcircle AND
	MAPNAME='logtempline' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'logtempline');
	$testnum++;
	print "ok $testnum logtempline OK\n";
#
#	barchart w/ temp. domain
#
tempbar:
	$sth = $dbh->prepare("select barchart, imagemap from templine
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Barchart Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLORS=red AND
	SHOWVALUES=1 AND 
	MAPNAME='tempbar' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'tempbar');
	$testnum++;
	print "ok $testnum tempbar OK\n";
#
#	histo w/ temp domain
#
temphisto:
	$sth = $dbh->prepare("select histogram, imagemap from templine2
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Temporal Histogram Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLORS=blue AND
	SHOWVALUES=1 AND 
	MAPNAME='temphisto' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'temphisto');
	$testnum++;
	print "ok $testnum temphisto OK\n";
#
#	composite (line, scatter)
#
complinept:
	$sth = $dbh->prepare("select image, imagemap from
	(select linegraph from simpline
		where color=newcolor and shape='fillcircle') simpline,
	(select pointgraph from simppie
		where color=blue and shape='opensquare') simppt
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Line/Pointgraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='complinept' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'complinept');
	$testnum++;
	print "ok $testnum complinept OK\n";
#
#	composite (area, line, scatter)
#
complpa:
	$dbh->do('create table complpa (x integer, y integer)');
	$sth = $dbh->prepare('insert into complpa values(?, ?)');

	$sth->execute($x[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select image, imagemap from
	(select linegraph from simpline
		where color=newcolor and shape=fillcircle) simpline,
	(select pointgraph from simppie
		where color=blue and shape=opensquare) simppt,
	(select areagraph from complpa
		where color=red) simparea
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Line/Point/Areagraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='complpa' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'complpa');
	$testnum++;
	print "ok $testnum complpa OK\n";
#
#	composite (area, bar, line, scatter)
#
compblpa:
	$sth = $dbh->prepare("select image, imagemap from
	(select linegraph from simpline
		where color=newcolor and shape=fillcircle) simpline,
	(select pointgraph from simppie
		where color=blue and shape=opensquare) simppt,
	(select areagraph from complpa
		where color=green) simparea,
	(select barchart from complpa
		where color=red) simpbar
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Bar/Line/Point/Areagraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='compblpa' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'compblpa');
	$testnum++;
	print "ok $testnum compblpa OK\n";
#
#	composite (line, box)
#
complnbox:
	$dbh->do('drop table simpbox');
	$dbh->do('create table simpbox (x integer)');
	$sth = $dbh->prepare('insert into simpbox values(?)');
	$sth->execute($_) foreach (@xbox);
	$dbh->do('create table complnbox (xfreq integer, yfreq integer)');
	$sth = $dbh->prepare('insert into complnbox values(?, ?)');
	$sth->execute($xfreq[$_], $yfreq[$_])
		foreach (0..$#xfreq);

	$sth = $dbh->prepare("select image, imagemap from
	(select linegraph from complnbox
		where color=red and shape=fillcircle) simpline,
	(select boxchart from simpbox
		where color=newcolor) simpbox
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Box and Line Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='complnbox' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'complnbox');
	$testnum++;
	print "ok $testnum complnbox OK\n";
#
#	composite (line, line, box, box)
#
compllbb:
	$dbh->do('create table simpbox2 (x integer)');
	$sth = $dbh->prepare('insert into simpbox2 values(?)');
	$sth->execute($_) foreach (@xbox2);
	$dbh->do('create table compllbb (xfreq2 integer, yfreq2 integer)');
	$sth = $dbh->prepare('insert into compllbb values(?, ?)');

	$sth->execute($xfreq2[$_], $yfreq2[$_])
		foreach (0..$#xfreq2);

	$sth = $dbh->prepare("select image, imagemap from
	(select linegraph from complnbox
		where color=newcolor and shape=fillcircle
		and showvalues=1) simpline,
	(select boxchart from simpbox
		where color=newcolor) simpbox,
	(select linegraph from compllbb
		where color=red and shape=fillcircle
		and showvalues=0) simpline2,
	(select boxchart from simpbox2
		where color=red) simpbox2
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Multiple Box and Line Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='compllbb' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'compllbb');
	$testnum++;
	print "ok $testnum compllbb OK\n";
#
#	composite (bar, bar, bar)
#
compbars:
	$sth = $dbh->prepare("select image, imagemap from
	(select barchart from simppie
		where color=red) bars1,
	(select barchart from complpa
		where color=blue) bars2
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Barchart Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND SHOWVALUES = 1 AND SHOWGRID=1 AND
	MAPNAME='compbars' AND ICONS=('t/pumpkin.png', 't/turkey.png' ) AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'compbars');
	$testnum++;
	print "ok $testnum compbars OK\n";
#
#	dense numeric graph (sin/cos)
denseline:
	$dbh->do('create table densesin (angle float, sine float)');
	$dbh->do('create table densecos (angle float, cosine float)');
	$sth = $dbh->prepare('insert into densesin values(?,?)');
	$sth2 = $dbh->prepare('insert into densecos values(?,?)');
	$i = 0;
	
	$sth->execute($i, sin($i)),
	$sth2->execute($i, cos($i)),
	$i += (PI/180)
		while ($i < 4*PI); 

	$sth = $dbh->prepare("select image from
	(select linegraph from densesin
		where color=red) densesin,
	(select linegraph from densecos
		where color=blue) densecos
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Dense Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Angle (Radians)' AND Y_AXIS='Sin/Cos' AND
	FORMAT='PNG'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'denseline', 1);
	$testnum++;
	print "ok $testnum denseline OK\n";

densearea:
	$sth = $dbh->prepare("select image from
	(select areagraph from densesin
		where color=red) densesin,
	(select areagraph from densecos
		where color=blue) densecos
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Dense Areagraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Angle (Radians)' AND Y_AXIS='Sin/Cos' AND
	FORMAT='PNG'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'densearea', 1);
	$testnum++;
	print "ok $testnum densearea OK\n";

simpgantt:
my @tasks = ( 'First task', '2nd Task', '3rd task', 'Another task', 'Final task');
my @starts = ( '2002-01-24', '2002-02-01', '2002-02-14', '2002-01-27', '2002-03-28');
my @ends = ( '2002-01-31', '2002-02-25', '2002-03-10', '2002-02-27', '2002-04-15');
my @assigned = ( 'DAA',       'DWE',       'SAM',       'KPD',        'WLA');
my @pct = (     25,            37,         0,          0,              0 );
my @depends = ( '3rd task',  'Final task', undef,    '2nd task',  undef);

	$dbh->do('create table simpgantt (task varchar(30),
		starts date, ends date, assignee varchar(3), pctcomplete integer, 
		dependent varchar(30))');
	$sth = $dbh->prepare('insert into simpgantt values(?,?,?,?,?,?)');
	$sth->execute($tasks[$_], $starts[$_], $ends[$_], $assigned[$_],
		$pct[$_], $depends[$_])
		foreach (0..$#tasks);

	$sth = $dbh->prepare("select gantt, imagemap from simpgantt
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Simple Gantt Chart Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Tasks' AND Y_AXIS='Schedule' AND
	COLOR=red AND LOGO='t/gowilogo.png' AND
	MAPNAME='simpgantt' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND
	X_ORIENT='VERTICAL' AND
	FORMAT='PNG'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'simpgantt');
	$testnum++;
	print "ok $testnum simpgantt OK\n";
#
#	stacked bar chart
#
stackbar:
	$dbh->do('create table stackbar (x integer, ylo integer, yhi integer)');
	$sth = $dbh->prepare('insert into stackbar values(?, ?, ?)');
	$sth->execute($x[$_], $y1[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select barchart, imagemap from stackbar
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Stacked Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND STACK=1 AND
	MAPNAME='stackbar' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('yellow', 'blue')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stackbar');
	$testnum++;
	print "ok $testnum stackbar OK\n";
#
#	stacked bar chart
#
stackicon:
	$sth = $dbh->prepare("select barchart, imagemap from stackbar
	where WIDTH=500 AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	and Y_AXIS='Some Range'
	AND TITLE='Stacked Iconic Barchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ICONS IN ('t/pumpkin.png', 't/turkey.png') 
	AND MAPNAME='stackbar' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stackicon');
	$testnum++;
	print "ok $testnum stackicon OK\n";
#
#	stacked histogram chart
#
stackhisto:
	$sth = $dbh->prepare("select histogram, imagemap from stackbar
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Stacked Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND STACK=1 AND
	MAPNAME='stackhisto' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('red', 'green')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stackhisto');
	$testnum++;
	print "ok $testnum stackhisto OK\n";
#
#	stacked area chart
#
stackarea:
	$dbh->do('drop table stackbar');
	$dbh->do('create table stackbar (x integer, ylo integer, yhi integer)');
	$sth = $dbh->prepare('insert into stackbar values(?, ?, ?)');
	$sth->execute($x[$_], $y2[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select areagraph, imagemap from stackbar
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Stacked Areagraph Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND STACK=1 AND
	MAPNAME='stackarea' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('red', 'green')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stackarea');
	$testnum++;
	print "ok $testnum stackarea OK\n";
#
#	stacked candlestick
#
stackcandle:
	$dbh->do('create table stackcandle (x integer, ylo integer, ymid integer, yhi integer)');
	$sth = $dbh->prepare('insert into stackcandle values(?, ?, ?, ?)');
	$sth->execute($x[$_], $y1[$_], $y2[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select candlestick, imagemap from stackcandle
	where WIDTH=300 AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS = 'Price' 
	AND TITLE='Stacked Candlestick Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND COLORS IN ('newcolor', 'red') 
	AND SHOWGRID=1 
	AND STACK=1 
	AND MAPNAME='stackcandle' 
	AND LINEWIDTH=5 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stackcandle');
	$testnum++;
	print "ok $testnum stackcandle OK\n";
#
#	multiline w/ NULL shape and map modifier
#
multilinemm:
	$sth = $dbh->prepare("select linegraph, imagemap from stackbar
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' and Y_AXIS='Some Range' AND
	TITLE='Multiline NULL Shape, Map Modifier Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND SHOWVALUES=1 AND
	MAPNAME='multilinemm' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' AND COLORS IN ('red', 'green')
	AND SHAPES IN (NULL, 'filldiamond')", { chart_map_modifier => \&modify_map });
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'multilinemm');
	$testnum++;
	print "ok $testnum multilinemm OK\n";
#
#	Quadtree test
#
quadtree:
@dataset = (
[ 'Retail', 'Specialty', 'Sharper Image', 100, 2.3 ],
[ 'Retail', 'Dept. Store', 'Nordstrom', 400, 1.2 ],
[ 'Retail', 'Discount', 'Walmart', 900, 1.5 ],
[ 'High Tech', 'Semiconductor', 'Intel', 1000, -2.1 ],
[ 'High Tech', 'Software', 'Microsoft', 1200, -1.1 ],
[ 'High Tech', 'Hardware', 'Dell', 800, 1.0 ],
[ 'High Tech', 'Biotech', 'Merck', 1000, 1.4 ],
[ 'Energy', 'Oil Producers', 'Exxon', 1200, -2 ],
[ 'Energy', 'Oil Discovery', 'Schumberger', 300, -1 ],
[ 'Energy', 'Power Utility', 'Edison', 800, -1.5 ],
[ 'Manufacturing', 'Automotive', 'GM', 1200, 3 ],
[ 'Manufacturing', 'Aerospace', 'Boeing', 1600, -3 ],
[ 'Manufacturing', 'Heavy Equipement', 'John Deere', 750, 0 ],
[ 'Manufacturing', 'Durable Goods', 'Whirlpool', 400, 2 ],
[ 'Manufacturing', 'Other', 'Fruit of the Loom', 100, -1.4 ],
[ 'Health Care', 'HMO', 'Kaiser', 1100, 2 ],
[ 'Health Care', 'Hospital', 'Bethel', 320, 0.5 ],
[ 'Health Care', 'Equipment', 'XYZ', 200, -0.4 ],
[ 'Health Care', 'Services', 'Medical Billing Inc', 250, 1.2 ],
[ 'Transportation', 'Airlines', 'UAL', 1000, -1 ],
[ 'Transportation', 'Trucking', 'Longhaul', 450, 1 ],
[ 'Transportation', 'Rails', 'Union Pacific', 1000, 2 ],
[ 'Telecomm', 'CLEC', 'Verizon', 1300, -1 ],
[ 'Telecomm', 'Long distance', 'ATT', 900, 1.1 ],
[ 'Telecomm', 'Wireless', 'Cingular', 550, 0.7 ],
[ 'Finance', 'Banks', 'Banc of America', 1400, 1.7 ],
[ 'Finance', 'Brokerages', 'Morgan Stanley', 760, 1 ],
[ 'Finance', 'Insurance', 'Allianz', 430, -1 ],
[ 'Service', 'Restaurant', 'YUM', 240, 1.1 ],
[ 'Service', 'Media', 'Tribune', 350, -1.3 ],
[ 'Service', 'Media', 'Disney', 690, -1 ]
);

$dbh->do('CREATE TABLE myquad (
		Sector		varchar(30),
		Subsector	varchar(30),
		Stock		varchar(30),
		RelMktCap	integer,
		PctChange	float)');
$sth = $dbh->prepare('insert into myquad values(?,?,?,?,?)');
$sth->execute(@{$_}) foreach (@dataset);

$sth = $dbh->prepare(
"SELECT QUADTREE, IMAGEMAP FROM myquad
WHERE COLORS IN ('red', 'black', 'green')
	AND WIDTH=500 AND HEIGHT=500
	AND TITLE='My Quadtree'
	AND MAPTYPE='HTML'
	AND MAPNAME='quadtree'
	AND MAPURL=
'http://www.presicient.com/cgi-bin/quadtree.pl?group=:X\&item=:Y\&value=:Z\&intensity=:PLOTNUM'");
$sth->execute;
$row = $sth->fetchrow_arrayref;
dump_img($row, 'png', 'quadtree');
	$testnum++;
print "ok $testnum quadtree OK\n";
#
#	3-D barchart
#
bar3d:
	$sth = $dbh->prepare("select barchart, imagemap from simpline
	where WIDTH=500 AND HEIGHT=500 AND X_AXIS='Some Domain' AND
	Y_AXIS='Some Range' AND
	TITLE='3-D Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	FORMAT='PNG' AND COLORS IN ('orange') AND
	THREE_D=1 AND SHOWGRID=1 AND
	MAPNAME='bar3d' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND BORDER=0
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'bar3d');
	$testnum++;
	print "ok $testnum bar3d OK\n";
#
#	3-axis bar chart
#
bar3axis:
	$dbh->do('create table bar3axis (Region varchar(10), Sales integer, Quarter CHAR(2))');
	$sth = $dbh->prepare('insert into bar3axis values(?, ?, ?)');
	$sth->execute($x3d[$_], $y3d[$_], $z[$_])
		foreach (0..$#x3d);
	$sth = $dbh->prepare("select barchart, imagemap from bar3axis
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='3 Axis Barchart Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Region' AND Y_AXIS='Sales' AND Z-AXIS='Quarter' AND
	FORMAT='PNG' AND COLORS IN ('red') AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='bar3axis' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'bar3axis');
	$testnum++;
	print "ok $testnum bar3axis OK\n";
#
#	3-D histogram
#
histo3d:
	$sth = $dbh->prepare("select histogram, imagemap from simppie
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND COLOR='orange' AND THREE_D=1 AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='histo3d' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'histo3d');
	$testnum++;
	print "ok $testnum histo3d OK\n";
#
#	3-axis histogram
#
histo3axis:
	$sth = $dbh->prepare("select histogram, imagemap from bar3axis
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='3 Axis Histogram Test' AND SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Region' AND Y_AXIS='Sales' AND Z_AXIS='Quarter' AND
	FORMAT='PNG' AND COLORS='red' AND
	SHOWGRID=1 AND SHOWVALUES=1 AND
	MAPNAME='histo3axis' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'histo3axis');
	$testnum++;
	print "ok $testnum histo3axis OK\n";
#
#	composite (histo, histo)
#
comphisto:
	$sth = $dbh->prepare("select image, imagemap from
	(select histogram from simppie
		where color=red) histo1,
	(select histogram from complpa
		where color=blue) histo2
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Composite Histogram Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND THREE_D=1 AND SHOWVALUES = 1 AND
	MAPNAME='comphisto' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'comphisto');
	$testnum++;
	print "ok $testnum comphisto OK\n";
#
#	stacked bar chart
#
stack3Dbar:
	$dbh->do('drop table stackbar');
	$dbh->do('create table stackbar (x integer, ylo integer, yhi integer)');
	$sth = $dbh->prepare('insert into stackbar values(?, ?, ?)');
	$sth->execute($x[$_], $y1[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select barchart, imagemap from stackbar
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Stacked 3-D Barchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND THREE_D=1
	AND MAPNAME='stack3Dbar'
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('yellow', 'blue')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stack3Dbar');
	$testnum++;
	print "ok $testnum stack3Dbar OK\n";
#
#	stacked histogram chart
#
stack3Dhisto:
	$sth = $dbh->prepare("select histogram, imagemap from stackbar
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Stacked 3-D Histogram Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND THREE_D=1
	AND	MAPNAME='stack3Dhisto' AND
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('red', 'green')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'stack3Dhisto');
	$testnum++;
	print "ok $testnum stack3Dhisto OK\n";
#
#	timestamp linegraph test
#
tmstamp:
	$dbh->do('create table tmstamp (x timestamp, y integer)');
	$sth = $dbh->prepare('insert into tmstamp values(?, ?)');
	$sth->execute($xtmstamp[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select linegraph, imagemap from tmstamp
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Timestamp Domain Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND MAPNAME='tmstamp' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('yellow', 'blue')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'tmstamp');
	$testnum++;
	print "ok $testnum tmstamp OK\n";
#
#	floated stacked bar chart
#
floatbar:
	$dbh->do('create table floatbar (
		x integer, ylo integer, ymid integer, yhi integer)');
	$sth = $dbh->prepare('insert into floatbar values(?, ?, ?, ?)');
	$sth->execute($x[$_], $y1[$_], $y2[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select barchart, imagemap from floatbar
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND	TITLE='Floating Stacked Barchart Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ANCHORED=0
	AND	MAPNAME='floatbar' 
	AND MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('yellow', 'blue', 'red')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'floatbar');
	$testnum++;
	print "ok $testnum floatbar OK\n";
#
#	floating stacked histogram chart
#
floathisto:
	$sth = $dbh->prepare("select histogram, imagemap from floatbar
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	and Y_AXIS='Some Range' 
	AND TITLE='Floating Stacked Histogram Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND	FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ANCHORED=0
	AND	MAPNAME='floathisto' 
	AND	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('red', 'green', 'orange')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'floathisto');
	$testnum++;
	print "ok $testnum floathisto OK\n";
#
#	floating stacked area chart
#
floatarea:
	$sth = $dbh->prepare("select areagraph, imagemap from floatbar
	where WIDTH=500 
	AND HEIGHT=500 
	AND X_AXIS='Some Domain' 
	AND Y_AXIS='Some Range' 
	AND TITLE='Floating Stacked Areagraph Test' 
	AND SIGNATURE='(C)2002, GOWI Systems' 
	AND	FORMAT='PNG' 
	AND SHOWVALUES=1 
	AND STACK=1 
	AND ANCHORED=0
	AND MAPNAME='floatarea' 
	AND	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X\&y=:Y\&z=:Z\&plotno=:PLOTNUM'
	AND MAPTYPE='HTML' 
	AND COLORS IN ('green', 'yellow', 'red')");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'floatarea');
	$testnum++;
	print "ok $testnum floatarea OK\n";
#
#	multline multiwidth chart
#
multwidth:
	$dbh->do('drop table floatbar');
	$dbh->do('create table floatbar (
		x integer, baseline integer, cold integer, warm integer, hot integer)');
	$sth = $dbh->prepare('insert into floatbar values(?, ?, ?, ?, ?)');
	$sth->execute(10, -50, -10, 50, 140);
	$sth->execute(50, -50, -10, 50, 140);

	$dbh->do('create table regline (x integer, ylo integer)');
	$dbh->do('create table fatline (x integer, ymid integer)');
	$dbh->do('create table midline (x integer, yhi integer)');
	$sth1 = $dbh->prepare('insert into regline values(?, ?)');
	$sth2 = $dbh->prepare('insert into fatline values(?, ?)');
	$sth3 = $dbh->prepare('insert into midline values(?, ?)');
	$sth1->execute($x[$_], $y1[$_]),
	$sth2->execute($x[$_], $y2[$_]),
	$sth3->execute($x[$_], $y3[$_])
		foreach (0..$#x);

	$sth = $dbh->prepare("select image, imagemap from
	(select areagraph from floatbar where anchored=0
		and stack=1 and colors in ('blue', 'yellow', 'red')),
	(select linegraph from regline
		where color='newcolor' and showvalues=1 ) regline,
	(select linegraph from fatline
		where color='lgray' and linewidth=10) fatline,
	(select linegraph from midline
		where color='green' and linewidth=4) midline
	where WIDTH=500 AND HEIGHT=500 AND 
	TITLE='Variable Width Linegraph Test' AND 
	SIGNATURE='(C)2002, GOWI Systems' AND
	X_AXIS='Some Domain' AND Y_AXIS='Some Range' AND
	FORMAT='PNG' AND 
	MAPNAME='multwidth' AND 
	MAPURL='http://www.gowi.com/cgi-bin/sample.pl?x=:X&y=:Y&z=:Z&plotno=:PLOTNUM'
	AND MAPTYPE='HTML'");
	$sth->execute;
	$row = $sth->fetchrow_arrayref;
	dump_img($row, 'png', 'multwidth');
	$testnum++;
	print "ok $testnum multwidth OK\n";

print HTMLF "</hmtl></body>\n";
close HTMLF;

sub dump_img {
	my ($row, $fmt, $fname, $nomap) = @_;
	open(OUTF, ">t/$fname.$fmt");
	binmode OUTF;
	print OUTF $$row[0];
	close OUTF;

	print HTMLF $$row[1], "\n" unless $nomap;
	1;
}

sub modify_map {
	my ($maphash) = @_;
	
	print 'Bad mapname ', $maphash->{Name}, "\n"
		if ($maphash->{Name} ne 'multilinemm');

	$maphash->{URL} = 'http://www.presicient.com/tdredux',
	$maphash->{AltText} = 'Changed it!',
	return 1
		if ($maphash->{PLOTNUM} == 1);

	$maphash->{URL} = 'http://www.google.com';
	$maphash->{AltText} = $maphash->{X} . ' secs, $' . $maphash->{Y};
	return 1;
}
