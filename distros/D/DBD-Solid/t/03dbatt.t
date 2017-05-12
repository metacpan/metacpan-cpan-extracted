#!/usr/bin/perl -I./t
$|=1;
print "1..$tests\n";

require DBI;
use DBD::Solid::Const qw(:sql_types);
use testenv;

my (@row);

my ($dsn, $user, $pass) = soluser();
print "ok 1\n";

my $dbh = DBI->connect($dsn, $user, $pass)
    or exit(0);
print "ok 2\n";

#### testing set/get of connection attributes

$dbh->{'AutoCommit'} = 1;
$rc = commitTest($dbh);
print " ", $DBI->errstr, "" if ($rc < 0);
print "not " unless ($rc == 1);
print "ok 3\n";

print "not " unless($dbh->{AutoCommit});
print "ok 4\n";

$dbh->{'AutoCommit'} = 0;
$rc = commitTest($dbh);
print $DBI->errstr, "\n" if ($rc < 0);
print "not" unless ($rc == 0);
print "ok 5\n";

my $sth;
my @exp_names = ('SOURCE', 'SOURCE_YEAR', 'CONFORMANCE', 'INTEGRITY', 
		      'IMPLEMENTATION', 'BINDING_STYLE', 'PROGRAMMING_LANG');
$sth = $dbh->prepare('SELECT * from SQL_LANGUAGES');
print "not " unless($sth);
if ($sth and $sth->execute()) 
    {
    my @name = @{$sth->{'NAME'}};
    my @null = @{$sth->{'NULLABLE'}};
    my @type = @{$sth->{'TYPE'}};
    my @prec = @{$sth->{'PRECISION'}};
    my @scale = @{$sth->{'SCALE'}};
    foreach (@name)
	{
	if ($_ ne shift(@exp_names)) { print "not "; last; }
	}
    print "";
    }
print "ok 6\n";
$sth->finish();

# --------------------------------------------
my %exp_type = 
    (
     'ID' 	                  => SQL_INTEGER,
     'PROCEDURE_NAME'         => SQL_WVARCHAR,
     'PROCEDURE_TEXT'         => SQL_WLONGVARCHAR,
     'PROCEDURE_BIN'          => SQL_LONGVARBINARY,
     'PROCEDURE_SCHEMA'       => SQL_WVARCHAR,
     'PROCEDURE_CATALOG'      => SQL_WVARCHAR,
     'CREATIME'               => SQL_TIMESTAMP,
     'TYPE'                   => SQL_INTEGER,
     'RS_ANAME_TUPLE_VERSION' => SQL_VARBINARY
    );

if ($sth = $dbh->prepare('SELECT * from SYS_PROCEDURES'))
   {
   my @type = @{$sth->{'TYPE'}};
   my @name = @{$sth->{'NAME'}};
   my $t;
   
  foreach (@name)
      {     
      unless ($exp_type{$_} eq ($t = shift(@type))) 
         {
         print sprintf('returned type "%d" for col "%s", expected "%d"',
                       $t, $_, $exp_type{$_}), "\n";
         print "not "; 
         last;
         }
      }
   }
else 
   { print "not "; }

print "ok 7\n";
$sth->finish();

#------------------------------------------------------------
print "not " unless ($sth = $dbh->prepare('SELECT * from TABLES'));
if ($sth)
    {
    if ($sth->execute())
	{
	while (@row = $sth->fetchrow())
	    {
	    $\ = " ";
	    foreach (@row) {print defined($_) ? $_ : 'NULL';}
	    $\ = "";
	    print "\n";
	    }
	}
    else 
	{
	print "not ";
	}
    $sth->finish();
    }
print "ok 8\n";

# ------------------------------------------------------------
$sth = $dbh->prepare('SELECT * from TABLES');
if ($sth)
    {
    print " CursorName is '$sth->{CursorName}'\n";
    print "not " unless ($sth->{'CursorName'});
#    print "not " unless ($sth->execute());
    }
else
    {
    print "not ";
    }
print "ok 9\n";
$sth->finish();

my $rows = 0;
if ($sth = $dbh->tables())
    {
    while (@row = $sth->fetchrow())
        {
        $rows++;
        }
    $sth->finish();
    }
print "not " unless $rows;
print "ok 10\n";


BEGIN { $tests = 10; }
$dbh->disconnect();

# ------------------------------------------------------------
# returns true when a row remains inserted after a rollback.
# this means that autocommit is ON. 
# ------------------------------------------------------------
sub commitTest
    {
    my $dbh = shift;
    my @row;
    my $rc;
    my $sth;

    $dbh->do('delete from perl_dbd_test where a = 100')
    or return undef;
    $dbh->commit();

    $dbh->do("insert into perl_dbd_test values(100, 'x', 'y')");
    $dbh->rollback();
    $sth = $dbh->prepare('SELECT a FROM perl_dbd_test WHERE a = 100');
    $sth->execute();
    if (@row = $sth->fetchrow()) 
	{
        $rc = 1;
	}
    else
	{
	$rc = 0;
	}
    $sth->finish();
    return $rc;
    }
# ------------------------------------------------------------

