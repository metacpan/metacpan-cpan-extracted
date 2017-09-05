use Test2::V0 -no_srand => 1;
use autodie;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::Memory;

my $store = AnyEvent::FTP::Server::Context::Memory->store;

my $t = create_ftpserver_ok('Memory');

$store->{foo} = {};
$store->{"bar.txt"} = "hi there";
$store->{"baz.txt"} = "and such";

$t->nlst_ok
  ->content_is("bar.txt\nbaz.txt\nfoo\n");

$t->nlst_ok('/')
  ->content_is("/bar.txt\n/baz.txt\n/foo\n");

$store->{stuff} = { map { $_ => $store->{$_} } keys %$store };

$t->nlst_ok('/stuff')
  ->content_is("/stuff/bar.txt\n/stuff/baz.txt\n/stuff/foo\n");

$t->nlst_ok('/stuff/bar.txt')
  ->content_is("/stuff/bar.txt\n");

todo 'wildcards' => sub {

$t->nlst_ok('/stuff/*')
  ->content_is("/stuff/bar.txt\n/stuff/baz.txt\n/stuff/foo\n");

};

done_testing;
