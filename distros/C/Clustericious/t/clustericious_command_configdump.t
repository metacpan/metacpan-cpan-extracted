use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;
use YAML::XS ();

requires undef, 12;
extract_data;
mirror 'example/etc' => 'etc';
mirror 'bin' => 'bin';

run_ok('hello', 'configdump')
  ->exit_is(0)
  ->note
  ->tap(sub {
    my($run) = @_;
    my $h = eval { YAML::XS::Load($run->out) };
    is $@, '', 'loads as yaml okay';
    is $h->{start_mode}, 'hypnotoad', 'has some expected data';
  });

run_ok('clustericious', 'configdump', 'Clustericious-HelloWorld')
  ->exit_is(0)
  ->note;

run_ok('clustericious', 'configdump', 'Bogus')
  ->exit_is(2)
  ->err_like(qr{ERROR: unable to find Bogus})
  ->note;

run_ok('clustericious', 'configdump', 'SyntaxError')
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
