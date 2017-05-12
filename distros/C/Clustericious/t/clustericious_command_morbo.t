use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;
use YAML::XS qw( Load );
use Path::Class qw( file );

requires undef, 4;
extract_data;

run_ok('hello', 'morbo', 'foo', 'bar', 'baz')
  ->exit_is(0)
  ->tap(sub {
    my @args = @{ Load(shift->out) };
    my $command = pop @args;
    like $command, qr{hello$}, 'seems to be the right command';
    is_deeply \@args, [qw( 
      -l http://1.2.3.4:5678
      foo bar baz
    )], 'arguments match';
  });

__DATA__

@@ bin/hello
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Clustericious::HelloWorld';
Clustericious::Commands->start;


@@ bin/morbo
#!/usr/bin/perl

use strict;
use warnings;
use YAML::XS qw( Dump );

print Dump(\@ARGV);


@@ etc/Clustericious-HelloWorld.conf
---
url: http://1.2.3.4:5678

