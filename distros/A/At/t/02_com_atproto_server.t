use strict;
use warnings;
use Test2::V0;
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At;
my $at = At->new( host => 'https://bsky.social' );
like $at->server->describeServer, {
    availableUserDomains => ['.bsky.social'],
    inviteCodeRequired   => !!1,                # XXX - Might be false in the future
    links                => {
        privacyPolicy  => qr[https://.+],       # https://blueskyweb.xyz/support/privacy-policy
        termsOfService => qr[https://.+]        # https://blueskyweb.xyz/support/tos
    },
    },
    'com.atproto.server.describeServer';
#
done_testing;
