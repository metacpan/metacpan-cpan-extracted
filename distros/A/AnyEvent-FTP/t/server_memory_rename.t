use strict;
use warnings;
use autodie;
use Test::More tests => 41;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

my $store = AnyEvent::FTP::Server::Context::Memory->store;

$store->{dir}->{"foo.txt"} = "hello there";

my $t = create_ftpserver_ok('Memory');

$t->command_ok(RNTO => "dir/bar.txt")
  ->code_is(503)
  ->message_is('Bad sequence of commands');

$t->command_ok(RNFR => "dir/bogus.txt")
  ->code_is(550)
  ->message_is('No such file or directory');

$t->command_ok(RNFR => "bogus/bogus.txt")
  ->code_is(550)
  ->message_is('No such file or directory');

$t->command_ok(RNFR => "dir/foo.txt")
  ->code_is(350)
  ->message_is('File or directory exists, ready for destination name');

$t->command_ok(RNTO => "dir/bar.txt")
  ->code_is(250)
  ->message_is('Rename successful');

ok !exists $store->{dir}->{"foo.txt"}, "file removed";
is $store->{dir}->{"bar.txt"}, "hello there", "file moved";

$store->{dir}->{"bar.txt"} = "hello there";
$store->{dir}->{"foo.txt"} = "hello there";

$t->command_ok(RNFR => "dir/foo.txt")
  ->code_is(350)
  ->message_is('File or directory exists, ready for destination name');

$t->command_ok(RNTO => "dir/bar.txt")
  ->code_is(550)
  ->message_is('File already exists');

$t->command_ok(RNFR => "dir/foo.txt")
  ->code_is(350)
  ->message_is('File or directory exists, ready for destination name');

$t->command_ok(RNTO => "bogus/bogus.txt")
  ->code_is(550)
  ->message_is('Rename failed');

$t->command_ok(RNFR => "/")
  ->code_is(550)
  ->message_is('No such file or directory');

$t->command_ok(RNFR => "../")
  ->code_is(550)
  ->message_is('No such file or directory');

$t->command_ok(RNFR => "dir/foo.txt")
  ->code_is(350)
  ->message_is('File or directory exists, ready for destination name');

TODO: { local $TODO = "shouldn't be able to rename to root";

$t->command_ok(RNTO => "/")
  ->code_is(550);

}
