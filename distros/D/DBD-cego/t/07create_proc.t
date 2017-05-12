use Test;
BEGIN { plan tests => 5 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
$line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/, $line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd");
ok($dbh);

my $sth;

$dbh->do("drop if exists procedure copytab;");
$dbh->do("drop if exists table srctab;");
$dbh->do("drop if exists table desttab;");


$sth = $dbh->do("create table srctab (a int , b string(20));");
ok($sth);

$sth = $dbh->do("create table desttab (a int , b string(20));");
ok($sth);

$sth = $dbh->do("create procedure copytab ( copyCond in int ) return int 
begin

   var copyCount int;
   :copyCount = 0;
 
   var ca int;
   var cb string(30);

   cursor copyCursor as select a, b from srctab where a = :copyCond;

   while fetch copyCursor into ( :ca, :cb ) = true
   begin
      insert into desttab values ( :ca, :cb );
      :copyCount = :copyCount + 1 ;
   end;

   return :copyCount;

end;");
ok($sth);

$dbh->disconnect;
ok($dbh);
