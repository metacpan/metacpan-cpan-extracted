use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;

requires undef, 18;
extract_data;
mirror 'example/etc' => 'etc';
mirror 'bin' => 'bin';

run_ok('hello', 'configdebug')
  ->exit_is(0)
  ->out_like(qr{etc/Clustericious-HelloWorld\.conf :: template\]})
  ->out_like(qr{etc/Clustericious-HelloWorld\.conf :: interpreted\]})
  ->out_like(qr{http://127\.0\.0\.1:5000})
  ->out_like(qr{\[merged\]})
  ->note;

run_ok('clustericious', 'configdebug', 'Clustericious-HelloWorld')
  ->exit_is(0)
  ->out_like(qr{etc/Clustericious-HelloWorld\.conf :: template\]})
  ->out_like(qr{etc/Clustericious-HelloWorld\.conf :: interpreted\]})
  ->out_like(qr{http://127\.0\.0\.1:5000})
  ->out_like(qr{\[merged\]})
  ->note;

run_ok('clustericious', 'configdebug', 'Bogus')
  ->exit_is(2)
  ->err_like(qr{ERROR: unable to find Bogus})
  ->note;

run_ok('clustericious', 'configdebug', 'SyntaxError')
  ->exit_is(2)
  ->err_like(qr{ERROR: in syntax:})
  ->note;

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
% extends_config 'hypnotoad', host => '127.0.0.1', port => 5000;


@@ etc/SyntaxError.conf
---
bogus bogus bogus
some bogus more
