use strict;
use Test;
BEGIN { plan tests => 8 }
use DBI;

open(DEF, "<dbd.def ") || die "File dbd.def not found\n";
my $line= <DEF>;
chop $line;
my ($host, $port,$tableset,$user,$pwd) = split(/:/,$line );
close(DEF);

my $dbh = DBI->connect("dbi:Cego:tableset=$tableset;hostname=$host;port=$port;protocol=serial;logfile=cegoDBD.log;logmode=debug", "$user", "$pwd");
ok($dbh);

$dbh->do("drop if exists procedure myInOut;");
# ok($dbh);

$dbh->do("create procedure myInOut ( myIn in int, myOut out string(20) ) return int 
begin
   var p1 int;
   var p2 string(20);  
  :myOut = 'TestString';
  return 42;
end;");
ok($dbh);
 
my $retVar= 111;
my $outVar= 333;
my $xVar= 333;

my $sth;

$sth = $dbh->prepare("? = call myInOut ( 2, ? );");
ok($sth);

$sth->bind_param_inout(1, \$retVar, 10);
$sth->bind_param_inout(2, \$outVar, 10);
# $sth->bind_param_inout(2, \$xVar, 10);
ok($sth);

$sth->execute;
ok($sth);

print "retVar=" . $retVar ."\n";
print "outVar=" . $outVar ."\n";
print "xVar=" . $xVar ."\n";

if ( $outVar eq "TestString" )
{
    ok( 1 );
}
else   
{
   ok( 0 );
}
$sth->finish;
ok($sth);

$dbh->disconnect;
ok($dbh);
