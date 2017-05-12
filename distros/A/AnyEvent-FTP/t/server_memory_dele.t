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

$t->command_ok(DELE => 'bar')
  ->code_is(250);

ok !exists $store->{bar}, "file deleted";

$t->command_ok(DELE => '/')
  ->code_is(550);

$t->command_ok(DELE => 'bar')
  ->code_is(550);

TODO: { local $TODO = "shouldn't be able to do a DELE on a directory";

$t->command_ok(DELE => 'foo')
  ->code_is(550);

}
