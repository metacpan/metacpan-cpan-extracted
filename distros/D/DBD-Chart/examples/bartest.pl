#!/usr/bin/perl -w
use DBI;
use DBD::Chart;

open(OUTF, ">bars.html");
print OUTF "<html><body>
<img src=simpbar.png>
<img src=multibar.png>
<img src=updbars.png>
<img src=delbars.png>
</body></html>\n";
close OUTF;

$dbh = DBI->connect('dbi:Chart:');
#
#	simple barchart
#
$dbh->do('CREATE TABLE bars (region CHAR(20), Revenue FLOAT)');
$sth = $dbh->prepare('INSERT INTO bars VALUES( ?, ?)');
$sth->execute('East', 2756.34);
$sth->execute('Southeast', -3456.78);
$sth->execute('Midwest', 1234.56);
$sth->execute('Southwest', -4569.78);
$sth->execute('Northwest', 8456.78);

$rsth = $dbh->prepare(
"SELECT BARCHART FROM bars 
	WHERE WIDTH=400 AND HEIGHT=400 AND X-AXIS=\'Region\' 
	AND Y-AXIS=\'Revenue\' AND TITLE = \'Revenue By Region\' 
	AND COLOR=(red, green, lyellow, blue, orange)
	AND SIGNATURE=\'Copyright(C) 2001, GOWI Systems, Inc.\'
	AND X-ORIENT=\'VERTICAL\' AND BACKGROUND=lgray");

$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpbar.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
$dbh->do('DROP CHART bars');
print "simpbar.png OK\n";
#
#	barchart, multidataset
#
$dbh->do('CREATE TABLE bars (quarter SMALLINT, East FLOAT, '.
'Southeast FLOAT, Midwest FLOAT, Southwest FLOAT, Northwest FLOAT)');
$sth = $dbh->prepare('INSERT INTO bars VALUES(?, ?, ?, ?, ?, ?)');
$sth->execute(1, -2756.34, 3456.78, 1234.56, -4569.78, 33456.78);
$sth->execute(2, 2756.34, 3456.78, 1234.56, 4569.78, 33456.78);
$sth->execute(3, 2756.34, 3456.78, -1234.56, 4569.78, 33456.78);
$sth->execute(4, 2756.34, -3456.78, 1234.56, 4569.78, 33456.78);

$rsth = $dbh->prepare('SELECT BARCHART FROM bars ' .
'WHERE WIDTH=600 AND HEIGHT=400 AND X-AXIS=\'Quarter\' AND Y-AXIS=\'Revenue\' AND ' .
'TITLE = \'Quarterly Revenue By Region\' AND 3-D=1 AND SHOWVALUES=1 AND ' .
'COLOR=(red, green, blue, yellow, dbrown)');
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>multibar.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "multibar.png OK\n";

$usth = $dbh->prepare('update bars set East=?, Southeast=?, ' .
'Midwest = 8675.0, Southwest = ?, Northwest = ? ' .
'where quarter > ?');
$usth->bind_param(1, 3895.3);
$usth->bind_param(2, 2444.22);
$usth->bind_param(3, 395.3);
$usth->bind_param(4, 12444.22);
$usth->bind_param(5, 2);
$usth->execute;

$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>updbars.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "updbars.png OK\n";

$dsth = $dbh->prepare('delete from bars where quarter = ?');
$dsth->bind_param(1, 3);
$dsth->execute;

$sth->execute(3, 2222.22, 3654.78, 2222.33, 1543.78, 1456.78);
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>delbars.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "delbars.png OK\n";
