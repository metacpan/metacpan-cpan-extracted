use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;

requires undef, 3;
mirror 'example/etc' => 'etc';
mirror 'bin' => 'bin';

run_ok('clustericious', 'configpath')
  ->exit_is(0)
  ->tap(sub {
    my @list = split /\r?\n/, shift->out;
    subtest 'valid directories' => sub {
      plan tests => scalar @list;
      ok -d $_, "$_ exists" for @list;
    };
  })
  ->note;


