#!/usr/bin/perl -w
use DBI;
use DBD::Chart;

open(OUTF, ">simparea.html");
print OUTF "<html><body>
<img src=simparea.png>
<img src=multarea.png>
</body></html>\n";
close OUTF;

$dbh = DBI->connect('dbi:Chart:');
#
# simple line graph
#
$dbh->do('CREATE CHART line (Month SMALLINT, sales FLOAT)');
$sth = $dbh->prepare('INSERT INTO line VALUES( ?, ?)');
$sth->execute(1, 2756.34);
$sth->execute(4, undef);
$sth->execute(8, 3456.78);
$sth->execute(9, 12349.56);
$sth->execute(10, 4569.78);
$sth->execute(5, 33456.78);
$sth->execute(6, 908.57);
$sth->execute(7, 756.34);
$sth->execute(11, 13456.78);
$sth->execute(12, 90.57);
$sth->execute(2, 3456.78);
$sth->execute(3, 1234.56);

$rsth = $dbh->prepare('SELECT AREAGRAPH FROM line ' .
'WHERE WIDTH=400 AND HEIGHT=400 AND X-AXIS=\'Month\' AND Y-AXIS=\'Sales\' AND ' .
'TITLE = \'Sales By Month\' AND COLOR=red AND SHOWGRID=1 AND SHOWPOINTS=0');
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simparea.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "simparea.png OK\n";

#
#	linepoint graph, multidataset
#
$dbh->do('DROP CHART line');
$dbh->do('CREATE CHART line (Month SMALLINT, East FLOAT, ' .
'Southeast float, Midwest float, Southwest float, Northwest float)');
$sth = $dbh->prepare('INSERT INTO line VALUES( ?, ?, ?, ?, ?, ?)');

@month = (1,2,3,4,5,6,7,8,9,10,11,12);
@east = ( 2756.34, 3456.90, 1234.99, 1005.34, 2876.34, 3456.78, undef, 4321.25, 9001.34, 997.68, 
	1234.56, 7783.20);
@seast = ( 5321.11, 3333.33, 876.10, 4569.78, 4326.3,  -7895.44, 4444.44, 12345.29, 3456.78, 
	12094.5, 6666.66, 3322.11);
@midwest = ( 9090.90, 908.57, -2367.4, 3399.55, 5555.55, 887.3, 756.34, 1111.11, 2222.22, 8888.88, 
	9456.3, undef);
@swest = ( 7783.20, 5321.11, 3333.33, 876.10, 12349.56, 12094.5, 6666.66, 3322.11, 9090.90,
	4569.78, 3456.99, 4321.25);
@nwest = ( 9001.34, 997.68, 13456.78, 2367.4, 3399.55, 5555.55, 887.3,
	90.57, 3456.90, 1234.99, undef, 2876.34);
	
$sth->func(1, \@month, chart_bind_param_array);
$sth->func(2, \@east, chart_bind_param_array);
$sth->func(3, \@seast, chart_bind_param_array);
$sth->func(4, \@midwest, chart_bind_param_array);
$sth->func(5, \@swest, chart_bind_param_array);
$sth->func(6, \@nwest, chart_bind_param_array);

%stsary = ();
$sth->func(\%stsary, chart_bind_param_status);

$sth->execute;

$rsth = $dbh->prepare('SELECT AREAGRAPH FROM line ' .
'WHERE WIDTH=400 AND HEIGHT=400 AND X-AXIS=\'Month\' AND Y-AXIS=\'Sales\' AND ' .
'TITLE = \'Monthly Sales By Region\' AND COLOR=(red, green, blue, yellow, lbrown) AND ' .
'SHOWPOINTS=1 AND SHOWGRID=1 AND SHAPE=(fillcircle, fillsquare, filldiamond, horizcross, diagcross)');
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>multarea.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "multarea.png OK\n";
