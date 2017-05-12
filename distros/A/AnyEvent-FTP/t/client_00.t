use strict;
use warnings;
use 5.010;
use Test::More;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

plan tests => 1;

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

prep_client( $client );

our $config;

$client->on_greeting(sub {
  my $res = shift;
  diag "$res";
});

$client->connect($config->{host}, $config->{port})->recv;

$client->quit->recv;

