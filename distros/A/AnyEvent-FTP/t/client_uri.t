use strict;
use warnings;
use 5.010;
use Test::More;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
use URI;
require "$FindBin::Bin/lib.pl";

plan skip_all => 'requires client and server on localhost' if $ENV{AEF_REMOTE};
plan tests => 12;

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

our $config;
our $detect;

prep_client( $client );

my $uri = URI->new('ftp:');
$uri->host($config->{host});
$uri->port($config->{port});
$uri->user($config->{user});
$uri->password($config->{pass});
$uri->path(do {
  my $dir = $config->{dir};
  if($^O eq 'MSWin32')
  {
    (undef,$dir,undef) = File::Spec->splitpath($dir,1);
    $dir =~ s{\\}{/}g;
  }
  $dir;
});
isa_ok $uri, 'URI';

do {
  my $res = eval { $client->connect($uri)->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 250, 'code = 250';
  is $client->pwd->recv, net_pwd($config->{dir}), "dir = " . net_pwd($config->{dir});
  $client->quit->recv;
};

do {
  my $res = eval { $client->connect($uri->as_string)->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 250, 'code = 250';
  is $client->pwd->recv, net_pwd($config->{dir}), "dir = " . net_pwd($config->{dir});
  $client->quit->recv;
};

$uri->user('bogus');
$uri->password('bogus');

SKIP: {
  skip 'bftp quit broken', 2 if $detect->{xb};
  eval { $client->connect($uri->as_string)->recv };
  my $error = $@;
  isa_ok $error, 'AnyEvent::FTP::Response';
  is $error->code, 530, 'code = 530';
  $client->quit->recv;
};

$uri->user($config->{user});
$uri->password($config->{pass});
$uri->path('/bogus/bogus/bogus');

SKIP: {
  skip 'bftp quit broken', 2 if $detect->{xb};
  eval { $client->connect($uri->as_string)->recv };
  my $error = $@;
  isa_ok $error, 'AnyEvent::FTP::Response';
  is $error->code, 550, 'code = 550';
  $client->quit->recv;
};
