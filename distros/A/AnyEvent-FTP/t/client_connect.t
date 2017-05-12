use strict;
use warnings;
use 5.010;
use Test::More tests => 15;
BEGIN { eval 'use EV' }
use AnyEvent::FTP::Client;
use FindBin ();
require "$FindBin::Bin/lib.pl";

my $done = AnyEvent->condvar;

my $client = eval { AnyEvent::FTP::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::FTP::Client';

$client->on_close(sub { $done->send });

our $config;

prep_client( $client );

do {
  my $condvar = eval { $client->connect($config->{host}, $config->{port}) };
  diag $@ if $@;
  
  my $res = eval { $condvar->recv };
  diag $@ if $@;
  
  isa_ok $res, 'AnyEvent::FTP::Response';
  is $res->code, 220, 'code = 220';
};

is eval { $client->push_command([USER => $config->{user}])->recv->code }, 331, 'code = 331';
diag $@ if $@;
is eval { $client->push_command([PASS => $config->{pass}])->recv->code }, 230, 'code = 230';
diag $@ if $@;

my $help_cv = $client->push_command(['HELP']);

is eval { $client->push_command(['QUIT'])                 ->recv->code }, 221, 'code = 221';
diag $@ if $@;

$done->recv;
$done = AnyEvent->condvar;

SKIP: {
  our $detect;
  skip 'bftp quit broken', 5 if $detect->{xb};
  is eval { $client->connect($config->{host}, $config->{port})->recv->code }, 220, 'code = 220';
  diag $@ if $@;

  is eval { $client->push_command([USER => 'bogus'])->recv->code }, 331, 'code = 331';
  diag $@ if $@;
  eval { $client->push_command([PASS => 'bogus'])->recv };
  is $@->code, 530, 'code = 530';
  is eval { $client->push_command(['QUIT'])                 ->recv->code }, 221, 'code = 221 (2)';
  diag $@ if $@;

  is $help_cv->recv->code, 214, 'code = 214';
  $done->recv;
  $done = AnyEvent->condvar;
}

my $cv1 = $client->push_command([USER => $config->{user}]);
my $cv2 = $client->push_command([PASS => $config->{pass}]);
my $cv3 = $client->push_command(['QUIT']);

is eval { $client->connect($config->{host}, $config->{port})->recv->code }, 220, 'code = 220';
diag $@ if $@;

is $cv1->recv->code, 331, 'code = 331';
is $cv2->recv->code, 230, 'code = 230';
is $cv3->recv->code, 221, 'code = 221';

$done->recv;
