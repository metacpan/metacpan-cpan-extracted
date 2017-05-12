use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;
use Clustericious::HelloWorld::Client;

requires 'apache24.conf', 2;
extract_data;
mirror 'example/etc' => 'etc';

$ENV{CLUSTERICIOUS_TEST_PORT} = generate_port;

foreach my $type (qw( cgi proxy ))
{

  subtest $type => sub {

    create_symlink "etc/Clustericious-HelloWorld-$type.conf" => 'etc/Clustericious-HelloWorld.conf';

    my $client = Clustericious::HelloWorld::Client->new;

    run_ok('hello', 'status')
      ->exit_is(2)
      ->note;

    run_ok('hello', 'start')
      ->exit_is(0)
      ->note;

    run_ok('hello', 'status')
      ->exit_is(0)
      ->note;

    is $client->welcome, 'Hello, world', 'client connects okay.';

    run_ok('hello', 'stop')
      ->exit_is(0)
      ->note;

    run_ok('hello', 'status')
      ->exit_is(2)
      ->note;

    note_file 'var/run/*.log';
    clean_file 'var/run/*.log';

  };
}

__DATA__

@@ bin/hello
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Clustericious::HelloWorld';
Clustericious::Commands->start;

@@ etc/Clustericious-HelloWorld-cgi.conf
---
% extends_config 'apache24-cgi', host => '127.0.0.1', port => $ENV{CLUSTERICIOUS_TEST_PORT} || 1234;

@@ etc/Clustericious-HelloWorld-proxy.conf
---
% extends_config 'apache24-proxy', host => $ENV{CLUSTERICIOUS_TEST_HOST}, port => $ENV{CLUSTERICIOUS_TEST_PORT} || 1234;
