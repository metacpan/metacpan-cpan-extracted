use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;
use YAML::XS qw( Load );
use File::HomeDir;
use Path::Class qw( file );

requires undef, 3;
extract_data;

run_ok('hello', 'daemon', 'foo', 'bar', 'baz')
  ->exit_is(0)
  ->tap(sub {
    my @args = @{ Load(shift->out) };
    is_deeply \@args, [ qw( 
      Clustericious::Command::daemon
      -l http://1.2.3.4:5678
      foo bar baz
    ) ], 'arguments are correct';
  });

__DATA__

@@ bin/hello
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Clustericious::HelloWorld';
Clustericious::Commands->start;


@@ lib/Mojolicious/Command/daemon.pm
package Mojolicious::Command::daemon;

use strict;
use warnings;
use YAML::XS qw( Dump );

sub run
{
  my($self, @args) = @_;
  print YAML::XS::Dump([ref $self, @args]);
}

1;


@@ etc/Clustericious-HelloWorld.conf
---
url: http://1.2.3.4:5678
