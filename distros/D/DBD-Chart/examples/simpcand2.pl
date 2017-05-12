#!/usr/bin/perl -w
use DBI;
use DBD::Chart;

$dbh = DBI->connect('dbi:Chart:');
#
# simple candle graph direct from database
#
$tddbh = DBI->connect('dbi:Teradata:wdevcop1', $ARGV[0], $ARGV[1],
	{ PrintError => 1, RaiseError => 0, AutoCommit => 1 });
$tddbh->do('DATABASE darnold1');
$tddbh->do('DROP TABLE candle');
$tddbh->do(
"CREATE TABLE candle (
	TradeDay DATE FORMAT 'YYYY-MM-DD', 
	lowprice FLOAT, 
	highprice FLOAT)"
);
$tdsth = $tddbh->prepare("INSERT INTO candle VALUES( ?, ?, ?)");
$tdsth->execute('2000-05-11', 27.34, 29.50);
$tdsth->execute('2000-05-12', 24.67, 28.50);
$tdsth->execute('2000-05-13', 22.34, 26.50);
$tdsth->execute('2000-05-14', 17.34, 20.50);
$tdsth->execute('2000-05-15', 17.34, 19.50);
$tdsth->execute('2000-05-18', 17.34, 21.50);
$tdsth->execute('2000-05-19', 18.34, 25.50);
$tdsth->execute('2000-05-20', 27.34, 39.50);
$tdsth->execute('2000-05-21', 30.34, 34.50);
$tdsth->execute('2000-05-22', 33.34, 37.50);
$tdsth->execute('2000-05-25', 32.34, 36.50);
$tdsth->execute('2000-05-26', 30.34, 32.50);
$tdsth->execute('2000-05-27', 28.34, 33.50);
$tdsth->execute('2000-05-28', 30.34, 38.50);
$tdsth->execute('2000-05-29', 27.34, 35.50);
$tdsth->execute('2000-06-01', 28.34, 34.50);
$tdsth->execute('2000-06-02', 25.34, 30.50);
$tdsth->execute('2000-06-03', 23.34, 28.50);
$tdsth->execute('2000-06-04', 20.34, 26.50);
 
$tdsth = $tddbh->prepare(
"SELECT TradeDay(VARCHAR(18)), lowprice, highprice
FROM candle ORDER BY TradeDay");
$tdsth->execute;

$rsth = $dbh->prepare("SELECT CANDLESTICK FROM ?
WHERE WIDTH=? AND HEIGHT=? AND X-AXIS=? AND Y-AXIS=? AND
TITLE = 'Daily Price Range' AND COLOR=red AND SHOWGRID=1 AND
SHAPE=filldiamond AND SHOWPOINTS=1 AND SHOWVALUES=0");
$rsth->execute($tdsth, 300,400, 'Date', 'Price');
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpcndl2.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
#
#	use same data to render linegraph with symbolic domain
#
$tdsth->execute;
$rsth = $dbh->prepare("SELECT LINEGRAPH FROM ?
WHERE WIDTH=400 AND HEIGHT=400 AND X-AXIS='Date' AND Y-AXIS='Price' AND
TITLE = 'Daily Price Range' AND COLOR=(red, blue) AND SHOWGRID=1 AND
SHAPE=(filldiamond, fillsquare) AND SHOWPOINTS=1");
$rsth->execute($tdsth);
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpsymb2.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
