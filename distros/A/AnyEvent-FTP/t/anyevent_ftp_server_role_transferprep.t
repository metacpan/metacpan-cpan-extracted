use Test2::V0 -no_srand => 1;
use AnyEvent::FTP::Server::Role::TransferPrep;
use strict;
use warnings;
use Test::AnyEventFTPServer;

global_timeout_ok(30);

foreach my $type (qw( FSRW Memory ))
{
  my $t = create_ftpserver_ok($type);

  $t->help_coverage_ok('AnyEvent::FTP::Server::Role::TransferPrep');

  $t->command_ok('REST')
    ->code_is(501)
    ->message_like(qr{REST requires});

  $t->command_ok('REST', 42)
    ->code_is(350)
    ->message_like(qr{Restarting at 42\.});

  $t->command_ok('PASV')
    ->code_is(227)
    ->message_like(qr{Entering Passive Mode \(127,0,0,1,\d+,\d+\)});
}

done_testing;
