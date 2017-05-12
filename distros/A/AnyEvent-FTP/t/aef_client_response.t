use strict;
use warnings;
use Test::More tests => 4;
use AnyEvent::FTP::Client::Response;

my $message = AnyEvent::FTP::Client::Response->new(227, [ 'Entering Passive Mode (192,168,42,23,156,29)' ]);

is $message->code, 227, 'code = 227';
like $message->message->[0], qr/Entering Passive Mode/, 'entering passive mode message';

my($ip, $port) = eval { $message->get_address_and_port };
diag $@ if $@;

# p1*256+p2
is $ip,   '192.168.42.23', 'ip = 192.168.42.23';
is $port, 156*256+29,      'port = ' . (156*256+29);
