#!/usr/local/bin/perl -w

use DBI;
use lib './blib/lib';
use lib './blib/arch';

sub sel
{
    print "# sel() \n";
    $sth = $dbh->prepare("select * from xx");
    warn $DBI::errstr unless $sth;
    $r = $sth->execute;
    print "rows = $r \n";
    warn $DBI::errstr if $r == 0;
    while (@r = $sth->fetchrow) { print join('|', @r), "\n"; }
    $s = $sth->finish or warn $DBI::errstr;
}

sub sel2
{
    print "# sel2() \n";
    $sth = $dbh->prepare("select * from xx");
    warn $DBI::errstr unless $sth;
    $sth2 = $dbh->prepare("select * from xx where sign = 'HEJA'");
    warn $DBI::errstr unless $sth2;
    $r = $sth->execute;
    $r2 = $sth2->execute;
    print "rows = $r + $r2 \n";
    warn $DBI::errstr if $r == 0 or $r2 == 0;
    while (@r = $sth->fetchrow) { print join('|', @r), "\n"; }
    while (@r = $sth2->fetchrow) { print join('|', @r), "\n"; }
    print "rows = ", $sth->rows, " + ", $sth2->rows, "\n";
    $namn = $sth->{NAME};
    $typer = $sth->{TYPE};
    $lens = $sth->{SIZE};
    print "NAMN: TYP: STLK:\n";
    for ($i = 0; $i  < scalar @$namn; $i++) 
    {
	print "$$namn[$i] \| $$typer[$i] \| $$lens[$i] \n"; 
    }
#    print "NAMN: $namn, TYP: $typer, LEN: $lens \n";
    $s = $sth->finish or warn $DBI::errstr;
    $s = $sth2->finish or warn $DBI::errstr;
}

$dbh = DBI->connect('kludd','','','Informix4');
die $DBI::errstr unless $dbh;

&sel;

$s = $dbh->do("create table xx (txt char(20), sign char(4), nr integer)");
warn("CT status = $s, err = " . $dbh->errstr) unless $s > 0;

&sel;

$s = $dbh->do("insert into xx values ('Hejsan', 'HEJ', 0)");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do('begin');
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do("insert into xx values ('Hejsan igen', 'HEJ1', 1)");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->rollback;
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do('begin');
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do("insert into xx values ('Hejsan igen', 'HEJ2', 2)");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do("insert into xx values ('Hejsan igen', 'HEJD', 3)");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->commit;
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do("update xx SET sign = 'HEJA' where sign = 'HEJ'");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;
$s = $dbh->do("delete from xx where sign = 'HEJD'");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;

&sel;
&sel2;

$s = $dbh->do("drop table xx");
warn("status = $s, err = " . $dbh->errstr) unless $s > 0;

$dbh->disconnect or die $DBI::errstr;
print "all done!\n";

1;
