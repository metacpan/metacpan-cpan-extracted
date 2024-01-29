use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Class qw[isa_ok can_ok];
#
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
#
use At;
subtest 'init' => sub {
    isa_ok my $at = At->new( host => 'https://bsky.social' ), ['At'], q[At->new( host => 'https://bsky.social' )];
    ok my $desc   = $at->server_describeServer(), '$at->server_describeServer()';
    like $desc->{availableUserDomains}, ['.bsky.social'], '... availableUserDomains';
    like $desc->{inviteCodeRequired},   !!1,              '... inviteCodeRequired';     # XXX - Might be false in the future
    isa_ok $desc->{links}, ['At::Lexicon::com::atproto::server::describeServer::links'], '... links';
    like $desc->{links}->_raw, {
        privacyPolicy  => qr[https://.+],                                               # https://blueskyweb.xyz/support/privacy-policy
        termsOfService => qr[https://.+]                                                # https://blueskyweb.xyz/support/tos
        },
        '... links->_raw';
};
#
subtest 'live' => sub {
    my $at = At->new( host => 'https://bsky.social', identifier => 'atperl.bsky.social', password => 'ck2f-bqxl-h54l-xm3l' );
    subtest 'server_listAppPasswords' => sub {
        ok my $pws = $at->server_listAppPasswords(), '$at->server_listAppPasswords()';
        isa_ok $pws->{passwords}->[0], ['At::Lexicon::com::atproto::server::listAppPasswords::appPassword'], 'correct type';
    };
    subtest 'server_getSession' => sub {
        ok my $ses = $at->server_getSession(), '$at->server_getSession()';
        isa_ok $ses->{handle}, ['At::Protocol::Handle'], '...handle';
        isa_ok $ses->{did},    ['At::Protocol::DID'],    '...did';
    };
    subtest '$at->can(...)' => sub {
        note 'running these tests are either impossible with an app password session or would modify the account in harmful ways';
        can_ok $at, [$_], $_
            for sort qw[server_getAccountInviteCodes server_updateEmail server_requestEmailUpdate server_revokeAppPassword server_resetPassword
            server_reserveSigningKey server_requestPasswordReset server_requestEmailConfirmation server_requestAccountDelete
            server_deleteSession server_deleteAccount server_createSession server_createInviteCodes server_createInviteCode
            server_createAppPassword server_createAccount server_confirmEmail server_refreshSession];
    }
};
#
done_testing;
