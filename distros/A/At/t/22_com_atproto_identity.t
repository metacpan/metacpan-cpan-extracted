use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At;
#
subtest 'live' => sub {
    my $at  = At->new( host => 'bsky.social' );
    my $res = $at->identity_resolveHandle('atproto.bsky.social');
    isa_ok $res->{did}, ['At::Protocol::DID'], 'handle is returned as an At::Protocol::DID object';
    is $res->{did}->_raw, 'did:plc:hrln33aoqxc5kdnwknaq3aki', q[yep, that's me];

    # Do not run these tests...
    can_ok $at, $_ for qw[identity_updateHandle];
};
#
done_testing;
