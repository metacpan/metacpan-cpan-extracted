use strict;
use warnings;
use 5.010;
use Test::More tests => 7;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

our $config;

prep_client($client);

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;

do {
  my $res = eval { $client->type('I')->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is eval { $res->code }, 200, 'code = 200';
  diag $@ if $@;
};

do {
  my $res = eval { $client->type('A')->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is eval { $res->code }, 200, 'code = 200';
  diag $@ if $@;
};

do {
  eval { $client->type('X')->recv };
  my $error = $@;
  isa_ok $error, 'AnyEvent::FTP::Response';
  like eval { $error->code }, qr{^50[104]$}, 'code = ' . eval { $error->code };
  diag $@ if $@;
};

$client->quit->recv;

