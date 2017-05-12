use strict;
use warnings;
use Test::More tests => 1;
use AnyEvent::Ident::Client;

my $client = eval { AnyEvent::Ident::Client->new(hostname => '127.0.0.1') };
diag $@ if $@;
isa_ok $client, 'AnyEvent::Ident::Client';
