use strict;
use warnings;
use Test::More tests => 2;
use AnyEvent::Open3::Simple;

my $ipc = AnyEvent::Open3::Simple->new;

isa_ok $ipc, 'AnyEvent::Open3::Simple';

eval { $ipc->run };

like $@, qr{run method requires at least one argument}, 'error';
