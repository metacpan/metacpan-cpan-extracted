use strict;
use warnings;
use 5.010;
use Test::More tests => 3;
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
$client->login($config->{user}, $config->{pass})->recv;

my $res = eval { $client->noop->recv };
diag $@ if $@;
isa_ok $res, 'AnyEvent::FTP::Response';
is eval { $res->code }, 200, 'code = 200';
diag $@ if $@;

$client->quit->recv;

