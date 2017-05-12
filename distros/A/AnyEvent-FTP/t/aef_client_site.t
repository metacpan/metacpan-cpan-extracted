use strict;
use warnings;
use Test::More tests => 4;
use AnyEvent::FTP::Client::Site;

my $client = bless {}, 'AnyEvent::FTP::Client';
my $site = eval { AnyEvent::FTP::Client::Site->new($client) };
isa_ok $site, 'AnyEvent::FTP::Client::Site';

isa_ok $site->proftpd,        'AnyEvent::FTP::Client::Site::Proftpd';
isa_ok $site->microsoft,      'AnyEvent::FTP::Client::Site::Microsoft';
isa_ok $site->net_ftp_server, 'AnyEvent::FTP::Client::Site::NetFtpServer';

package AnyEvent::FTP::Client;

BEGIN { $INC{'AnyEvent/FTP/Client.pm'} = __FILE__ }
