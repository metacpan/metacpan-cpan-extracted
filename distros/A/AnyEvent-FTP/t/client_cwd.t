use strict;
use warnings;
use 5.010;
use Test::More;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

plan skip_all => 'requires client and server on localhost' if $ENV{AEF_REMOTE};
plan tests => 8;

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

prep_client( $client );

our $config;

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;

do {
  my $res = eval { $client->cwd($config->{dir})->recv };
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 250, 'code = 250';
};

do {
  my $res = eval { $client->pwd->recv };
  is $res, net_pwd($config->{dir}), "dir = " . net_pwd($config->{dir});
};

do {

  $client->cwd('t')->recv;
  isnt $client->pwd->recv, $config->{dir}, "in t dir";
  
  my $res = eval { $client->cdup->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 250, 'code = 250';
  is $client->pwd->recv, net_pwd($config->{dir}), "dir = " . net_pwd($config->{dir});

};

$client->quit->recv;

