use Test2::V0 -no_srand => 1;
use Test::AnyEventFTPServer;
use AnyEvent::FTP::Server::Context::FSRW;

my $server = create_ftpserver_ok('FSRW');
$server->help_coverage_ok;

done_testing;
