use strict;
use warnings;
use 5.010;
use Test::More tests => 6;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

prep_client( $client );

our $config;

$client->connect($config->{host}, $config->{port})->recv;

my $res = eval { $client->login($config->{user}, $config->{pass})->recv };
diag $@ if $@;
isa_ok $res, 'AnyEvent::FTP::Response';

is $res->code, 230, 'code = 230';

is eval { $client->quit->recv->code }, 221, 'code = 221';
diag $@ if $@;

$client->connect($config->{host}, $config->{port})->recv;

eval { $client->login('bogus', 'bogus')->recv };
my $error = $@;
isa_ok $error, 'AnyEvent::FTP::Response';
is $error->code, 530, 'code = 530';

eval { $client->quit->recv };
