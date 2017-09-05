use Test2::V0 -no_srand => 1;
use autodie;
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

todo "shouldn't be able to do a DELE on a directory" => sub {

$t->command_ok(DELE => 'foo')
  ->code_is(550);

};

done_testing;
