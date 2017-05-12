package
  Foo::Bar::Baz;

use strict;
use warnings;
use Test::More tests => 1;
use AnyEvent::Open3::Simple;

my $ipc = eval { AnyEvent::Open3::Simple->new };
diag $@ if $@;
isa_ok $ipc, 'AnyEvent::Open3::Simple';
