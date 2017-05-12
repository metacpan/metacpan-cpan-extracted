#!/usr/bin/perl -w
use DBI;
use DBD::Chart;
open(OUTF, ">simpylog.html");
print OUTF "<html><body>
<img src=simpylog.png>
</body></html>\n";
close OUTF;

$dbh = DBI->connect('dbi:Chart:');
#
# simple line graph
#
$dbh->do('CREATE CHART line (Month FLOAT, sales FLOAT)');
$sth = $dbh->prepare('INSERT INTO line VALUES( ?, ?)');
for ($i = -3; $i < 13; $i++) {
# print $i, ', ', exp($i), "\n";
$sth->execute(5**$i, exp($i));
}

$rsth = $dbh->prepare('SELECT LINEGRAPH FROM line ' .
'WHERE WIDTH=450 AND HEIGHT=450 AND X-AXIS=\'5**X\' AND '.
'Y-AXIS=\'e**X\' AND ' .
'Y-LOG=1 AND X-LOG=1 AND SHOWVALUES=0 AND ' .
'TITLE = \'Sample Log-Log Linegraph\' AND COLOR=lred AND SHOWGRID=1 AND SHOWPOINTS=1');
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpylog.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "simpylog.png OK\n";
