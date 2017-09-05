use Test2::V0 -no_srand => 1;
use autodie;
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

todo "shouldn't be able to MKD on root" => sub {

$t->command_ok(MKD => '../../')
  ->code_is(550);

};

done_testing;
