use Test2::V0 -no_srand => 1;
use autodie;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

my $store = AnyEvent::FTP::Server::Context::Memory->store;

$store->{dir}->{"foo.txt"} = "hello there";

my $t = create_ftpserver_ok('Memory');

$t->command_ok(STAT => "/bogus.txt")
  ->code_is(450)
  ->message_is('No such file or directory');

$t->command_ok(STAT => "/dir/foo.txt")
  ->code_is(211)
  ->message_is("It's a file");

$t->command_ok(STAT => "/dir")
  ->code_is(211)
  ->message_is("It's a directory");

$t->command_ok(STAT => "/")
  ->code_is(211)
  ->message_is("It's a directory");

$t->command_ok(STAT => "..")
  ->code_is(211)
  ->message_is("It's a directory");

$t->command_ok(STAT => ".././/bogus.txt")
  ->code_is(450)
  ->message_is('No such file or directory');

done_testing;
