use strict;
use warnings;
use autodie;
use Test::More tests => 10;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

my $store = AnyEvent::FTP::Server::Context::Memory->store;

$store->{foo} = {};
$store->{bar} = "hi there";

my $t = create_ftpserver_ok('Memory');

$t->command_ok(RMD => 'foo')
  ->code_is(250);

ok !exists $store->{foo}, "directory deleted";

$t->command_ok(RMD => '/')
  ->code_is(550);

$t->command_ok(RMD => 'foo')
  ->code_is(550);

TODO: { local $TODO = "shouldn't be able to RMD a file";

$t->command_ok(RMD => 'bar')
  ->code_is(550);

}
