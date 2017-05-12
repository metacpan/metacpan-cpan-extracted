use strict;
use warnings;
use Test::More tests => 1;
use AnyEvent::Finger::Client;

my $client = eval { AnyEvent::Finger::Client->new };
diag $@ if $@;
isa_ok $client, 'AnyEvent::Finger::Client';
