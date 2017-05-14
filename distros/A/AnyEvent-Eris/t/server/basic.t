use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('AnyEvent::eris::Server') }

subtest 'Spawning' => sub {
    my $server = AnyEvent::eris::Server->new();
    isa_ok( $server, 'AnyEvent::eris::Server' );
};
