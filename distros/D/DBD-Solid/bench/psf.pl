require DBI;
$| = 1;

my $dbh;
$dbh = DBI->connect('', 'test', 'test', 'Solid')
       or die($DBI::errstr) unless($dbh);


psf_select_pk1($dbh);
psf_select_all($dbh);

$dbh->disconnect();

sub psf_select_pk1
{
my $dbh = shift;

my $sth = $dbh->prepare('SELECT max(psf_psid) from personfix')
    or die("prepare: $DBI::errstr");
$sth->execute()
    or die("execute: $DBI::errstr");
$psid_max = $sth->fetchrow();
$sth->finish();

my $sth = $dbh->prepare('SELECT min(psf_psid) from personfix')
    or die("prepare: $DBI::errstr");
$sth->execute()
    or die("execute: $DBI::errstr");
$psid_min = $sth->fetchrow();
$sth->finish();

print "-> random, part of primary key $psid_min ... $psid_max\n";

$sth = $dbh->prepare('SELECT * from personfix where psf_psid=?')
    or die("prepare: $DBI::errstr");

my ($psid, $found, $notfound, $t1, $t2, $dt);
$found = $notfound = 0;
$t1 = time();
for ($c = 0; $c < 1000; $c++)
    {
    $psid = int (rand($psid_max - $psid_min) + $psid_min);
    $sth->execute($psid)
        or die("execute: $DBI::errstr");

    print $c,"\r" unless ($c % 100);

    if (@row = $sth->fetchrow())
    	{
	$found++;
	}
    else
    	{
	$notfound++;
	}
    $sth->finish();
    }
$t2 = time();
$dt = $t2 - $t1;
print sprintf("Select random, 1000 rows: %d rows found, %d seconds (%02d:%02d)\n", 
	$found, $dt, $dt/60, $dt % 60);
$sth->finish();
}


sub psf_select_all
{
my $dbh = shift;
my $t1 = time();
print "-> select all\n";
my $sth = $dbh->prepare('SELECT * from personfix')
    or die("prepare: $DBI::errstr");
$sth->execute()
    or die("execute: $DBI::errstr");
$, = " ";
my @names=@{$sth->{NAME}};
print $names[0], $names[1], $names[2], $names[3], $names[4], $names[5], $names[18],"\n";
my $count = 0;
while (@row = $sth->fetchrow())
     {
     # print $row[0], $row[1], $row[2], $row[3], $row[4], $row[5], $row[18],"\n";
     $count++;
     print $count,"\r" unless ($count % 1000);
     }
print $DBI::errstr, "\n";
$sth->finish();
my $t2 = time();
my $dt = $t2 - $t1;
print sprintf("Select *: %d rows, %d seconds (%02d:%02d)\n", 
	$count, $dt, $dt/60, $dt % 60);
}
