use strict;
use warnings;
use 5.010;
use Test::More;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

my $client = AnyEvent::FTP::Client->new;

prep_client( $client );
our $config;

$client->connect($config->{host}, $config->{port})->recv;
$client->login($config->{user}, $config->{pass})->recv;

our $detect;
plan skip_all => 'wu-ftpd does not support ALLO' if $detect->{wu};
plan skip_all => 'proftpd does not support ALLO' if $detect->{pr};
plan tests => 4;

my $res = eval { $client->allo('foo')->recv };
diag $@ if $@;
isa_ok $res, 'AnyEvent::FTP::Response';
like eval { $res->code }, qr{^20[02]$}, 'code = ' . eval { $res->code };
diag $@ if $@;

SKIP: {
  skip 'pure-ftpd does not support ALLO without argument', 2 if $detect->{pu};
  skip 'IIS does not support ALLO without argument', 2 if $detect->{ms};

  my $res = eval { $client->allo->recv };
  diag $@ if $@;
  isa_ok $res, 'AnyEvent::FTP::Response';
  like eval { $res->code }, qr{^20[02]$}, 'code = ' . eval { $res->code };
  diag $@ if $@;
}

$client->quit->recv;

