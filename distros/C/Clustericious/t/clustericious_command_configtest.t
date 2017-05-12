use strict;
use warnings;
use Test::Clustericious::Command;
use Test::More;

requires undef, 5;
extract_data;
mirror 'bin' => 'bin';

$ENV{CLUSTERICIOUS_SANE} = 1;

run_ok('foo', 'configtest')
  ->exit_is(0)
  ->out_like(qr{config okay})
  ->note;

$ENV{CLUSTERICIOUS_SANE} = 0;

run_ok('foo', 'configtest')
  ->exit_is(2)
  ->note;

__DATA__

@@ bin/foo
#!/usr/bin/perl

use strict;
use warnings;
use Clustericious::Commands;
$ENV{MOJO_APP} = 'Foo';
Clustericious::Commands->start;


@@ lib/Foo.pm
package Foo;

use strict;
use warnings;
use base qw( Clustericious::App );

sub sanity_check { $ENV{CLUSTERICIOUS_SANE} }

1;
