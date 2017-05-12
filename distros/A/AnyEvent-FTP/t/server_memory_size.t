use strict;
use warnings;
use autodie;
use Test::More tests => 10;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

AnyEvent::FTP::Server::Context::Memory->store->{top} = {
  'hello.txt' => "1234567890",
  dir         => { },
};

my $t = create_ftpserver_ok('Memory');

$t->command_ok(SIZE => "/top/hello.txt")
  ->code_is(213)
  ->message_is(10);

$t->command_ok(SIZE => "/top/bogus.txt")
  ->code_is(550)
  ->message_is("/top/bogus.txt: No such file or directory");

$t->command_ok(SIZE => "/top/dir")
  ->code_is(550)
  ->message_is("/top/dir: not a regular file");
