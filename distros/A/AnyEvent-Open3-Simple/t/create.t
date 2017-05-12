use strict;
use warnings;
use Test::More tests => 2;
use AnyEvent::Open3::Simple;
use AnyEvent::Open3::Simple::Process;

my $ipc = eval { AnyEvent::Open3::Simple->new };
diag $@ if $@;
isa_ok $ipc, 'AnyEvent::Open3::Simple';

my $proc = eval { no warnings 'once'; AnyEvent::Open3::Simple::Process->new(42, \*foo) };
diag $@ if $@;
isa_ok $proc, 'AnyEvent::Open3::Simple::Process';

