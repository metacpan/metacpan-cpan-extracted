#!/usr/bin/perl -w
use DBI;
use DBD::Chart;

open(OUTF, ">simpcandle.html");
print OUTF "<html><body>
<img src=simpcndl.png>
<img src=simpsymb.png>
</body></html>\n";
close OUTF;

$dbh = DBI->connect('dbi:Chart:');
#
# simple candle graph
#
$dbh->do('CREATE CHART candle (Day DATE, low FLOAT, high FLOAT)');
$sth = $dbh->prepare('INSERT INTO candle VALUES( ?, ?, ?)');
$sth->execute('2000-05-11', 27.34, 29.50);
$sth->execute('2000-05-12', 24.67, 28.50);
$sth->execute('2000-05-13', 22.34, 26.50);
$sth->execute('2000-05-14', 17.34, 20.50);
$sth->execute('2000-05-15', 17.34, 19.50);
$sth->execute('2000-05-18', 17.34, 21.50);
$sth->execute('2000-05-19', 18.34, 25.50);
$sth->execute('2000-05-20', 27.34, 39.50);
$sth->execute('2000-05-21', 30.34, 34.50);
$sth->execute('2000-05-22', 33.34, 37.50);
$sth->execute('2000-05-25', 32.34, 36.50);
$sth->execute('2000-05-26', 30.34, 32.50);
$sth->execute('2000-05-27', 28.34, 33.50);
$sth->execute('2000-05-28', 30.34, 38.50);
$sth->execute('2000-05-29', 27.34, 35.50);
$sth->execute('2000-06-01', 28.34, 34.50);
$sth->execute('2000-06-02', 25.34, 30.50);
$sth->execute('2000-06-03', 23.34, 28.50);
$sth->execute('2000-06-04', 20.34, 26.50);

$rsth = $dbh->prepare(
'SELECT CANDLESTICK FROM candle
WHERE WIDTH=? AND HEIGHT=? AND X-AXIS=? AND Y-AXIS=? AND 
TITLE = \'Daily Price Range\' AND COLOR=red AND SHOWGRID=1 AND 
SHAPE=filldiamond AND SHOWPOINTS=1 AND SHOWVALUES=0');
$rsth->execute(300,400, 'Date', 'Price');
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpcndl.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "simpcndl.png OK\n";

#
#	use same data to render linegraph with symbolic domain
#
$rsth = $dbh->prepare(
'SELECT LINEGRAPH FROM candle
WHERE WIDTH=500 AND HEIGHT=400 AND X-AXIS=\'Date\' AND Y-AXIS=\'Price\' AND
TITLE = \'Daily Price Range\' AND COLOR=(red, blue) AND SHOWGRID=1 AND
SHAPE=(filldiamond, fillsquare) AND SHOWPOINTS=1');
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpsymb.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "simpsymb.png OK\n";
