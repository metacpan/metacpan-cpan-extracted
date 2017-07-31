use strict;
use warnings;
use Test2::Plugin::FauxHomeDir;
use Test::More;

BEGIN {
  plan skip_all => 'test does not work on MSWin32' if $^O eq 'MSWin32';
  plan skip_all => 'test requires AnyEvent::Open3::Simple and EV'
    unless eval q{
      use EV;
      use AnyEvent;
      use AnyEvent::Open3::Simple;
      1;
    };
}

use Test::Clustericious::Command;
use Clustericious::HelloWorld::Client;

requires 'plackup.conf', 1;
extract_data;
mirror 'example/etc' => 'etc';

$ENV{CLUSTERICIOUS_TEST_PORT} = generate_port;

my %proc;

sub finish
{
  foreach my $proc (values %proc)
  {
    note "killing ", $proc->pid;
    kill 9, $proc->pid;
  }
}

our $anyevent_test_timeout = AnyEvent->timer(
  after => 20,
  cb => sub {
  
    diag "TIMEOUT: giving up";

    finish();

    exit;
  },
);

my $plackup = do {

  my $ready = AnyEvent->condvar;

  my $plackup = AnyEvent::Open3::Simple->new(
    on_start => sub {
      my ($proc, @command) = @_;
      note "[plackup] % @command";
      $proc{$proc->pid} = $proc;
    },
    on_stdout => sub {
      my($proc, $line) = @_;
      note "[plackup] [out] $line";
    },
    on_stderr => sub {
      my($proc, $line) = @_;
      note "[plackup] [err] $line";
      $ready->send if $ready && $line =~ /HTTP::Server::PSGI: Accepting connections/;
    },
    on_error => sub {
      my($error, @command) = @_;
      diag "[plackup] % @command";
      diag "[plackup] [FAIL] $error";
    },
  );

  $plackup->run('hello', 'plackup');

  $ready->recv;

  $plackup;
};

my $client = Clustericious::HelloWorld::Client->new;
is $client->welcome, 'Hello, world', 'client connects okay.';

finish();

__DATA__

@@ bin/hello
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Clustericious::HelloWorld';
Clustericious::Commands->start;

@@ etc/Clustericious-HelloWorld.conf
---
url: http://127.0.0.1:<%= $ENV{CLUSTERICIOUS_TEST_PORT} %>

