use strict;
use warnings;
use 5.010;
use Test::AnyEventFTPServer;
use Test::More;

my $t = create_ftpserver_ok('FSRW');
$t->auto_login(0);

my @cmd = qw( CWD CDUP PWD SIZE MKD RMD DELE RNFR RNTO STAT PASV PORT REST RETR NLST LIST STOR 
APPE STOU ALLO NOOP SYST TYPE );

foreach my $cmd (@cmd)
{
  $t->command_ok($cmd)
    ->code_is(530)
    ->message_like(qr{Please login with USER and PASS});
}

done_testing;
