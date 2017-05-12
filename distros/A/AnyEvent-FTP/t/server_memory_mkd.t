use strict;
use warnings;
use autodie;
use Test::More tests => 14;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

my $store = AnyEvent::FTP::Server::Context::Memory->store;

my $t = create_ftpserver_ok('Memory');

$t->command_ok(MKD => 'foo')
  ->code_is(257);

is ref($store->{foo}), 'HASH', 'created directory';

$t->command_ok(MKD => 'foo')
  ->code_is(521);

$t->command_ok(MKD => '/foo')
  ->code_is(521);

$t->command_ok(MKD => '../.././foo')
  ->code_is(521);

$t->command_ok(MKD => '/')
  ->code_is(550);

TODO: { local $TODO = "shouldn't be able to MKD on root";

$t->command_ok(MKD => '../../')
  ->code_is(550);

}
