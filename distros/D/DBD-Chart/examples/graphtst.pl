#!/usr/bin/perl -w
use DBI;
use DBD::Chart;

open(OUTF, ">graphs.html");
print OUTF "<html><body>
<img src=simpline.png>
<img src=simppts.png >
<img src=multipt.png >
</body></html>\n";
close OUTF;

$dbh = DBI->connect('dbi:Chart:');
#
# simple line graph
#
$dbh->do('CREATE CHART line (Month SMALLINT, sales FLOAT)');
$sth = $dbh->prepare('INSERT INTO line VALUES( ?, ?)');
$sth->execute(201, 2756.34);
$sth->execute(204, undef);
$sth->execute(208, 3456.78);
$sth->execute(209, 12349.56);
$sth->execute(210, 4569.78);
$sth->execute(205, 33456.78);
$sth->execute(206, 908.57);
$sth->execute(207, 756.34);
$sth->execute(211, 13456.78);
$sth->execute(212, 90.57);
$sth->execute(202, 3456.78);
$sth->execute(203, 1234.56);

$rsth = $dbh->prepare(
"SELECT LINEGRAPH FROM line
	WHERE WIDTH=400 AND HEIGHT=400 AND X-AXIS=\'Month\' AND Y-AXIS=\'Sales\' AND
	TITLE = \'Sales By Month\' AND COLOR=black AND SHOWGRID=1 AND SHOWPOINTS=0 AND
	LOGO=\'gowilogo.png\' AND BACKGROUND=lyellow AND KEEPORIGIN=1 AND
	X-ORIENT=\'VERTICAL\' AND SIGNATURE=\'Copyright(C) 2001, GOWI Systems, Inc.\'");
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simpline.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "simpline.png OK\n";
#
#	simple point graph
#
$rsth = $dbh->prepare('SELECT POINTGRAPH FROM line ' .
'WHERE WIDTH=500 AND HEIGHT=300 AND Y-AXIS=\'Sales\' AND X-AXIS=\'Month\' AND ' .
'TITLE = \'Sales By Region\' AND COLOR=black AND SHOWGRID=0 AND ' .
'X-ORIENT=\'VERTICAL\' AND SHAPE=filldiamond AND SHOWVALUES=1 AND BACKGROUND=transparent');
$rsth->execute;
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>simppts.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "simppts.png OK\n";

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

$rsth = $dbh->prepare(
"SELECT LINEGRAPH FROM line
	WHERE WIDTH=? AND HEIGHT=? AND X-AXIS=? AND Y-AXIS=? AND
	TITLE = \'Monthly Sales By Region\' AND 
	COLOR=(red, green, blue, yellow, lbrown) AND
	SHOWPOINTS=1 AND SHOWGRID=1 AND 
	SHAPE=(fillcircle, fillsquare, filldiamond, horizcross, diagcross) AND
	LOGO=\'gowilogo.png\' AND BACKGROUND=lgray AND 
	X-ORIENT=\'VERTICAL\' AND SIGNATURE=\'Copyright(C) 2001, GOWI Systems, Inc.\'");
$rsth->execute(400, 400, 'Month', 'Sales');
$rsth->bind_col(1, \$buf);
$rsth->fetch;
open(OUTF, '>multipt.png');
binmode OUTF;
print OUTF $buf;
close(OUTF);
print "multipt.png OK\n";
