use strict;
use warnings;
use Test::More tests => 11;
use Test::AnyEventFTPServer;

global_timeout_ok;

foreach my $type (qw( FSRW Memory ))
{
  my $server = create_ftpserver_ok($type);
  my $client = $server->connect_ftpclient_ok;
  
  is $client->help->recv->code, 214, "HELP";
  is $client->help('HELP')->recv->code, 214, "HELP HELP";
  is eval { $client->help('bogus command')->recv} || $@->code, 502, "HELP bogus command";
}
