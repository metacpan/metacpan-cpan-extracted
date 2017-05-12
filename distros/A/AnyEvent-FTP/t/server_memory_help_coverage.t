use strict;
use warnings;
use Test::More tests => 2;
use Test::AnyEventFTPServer;

my $server = create_ftpserver_ok('Memory');
$server->help_coverage_ok;
