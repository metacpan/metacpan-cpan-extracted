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
my $at = At->new( host => 'nope.net' );
#
isa_ok(
    At::Lexicon::com::atproto::admin::communicationTemplateView->new(
        id              => '12345',
        name            => 'Warning',
        subject         => 'This is a warning',
        contentMarkdown => '**bold** etc.',
        disabled        => !1,
        lastUpdatedBy   => 'did:web:fdsafdafdsafdlsajkflds',
        createdAt       => time,
        updatedAt       => time
    ),
    ['At::Lexicon::com::atproto::admin::communicationTemplateView'],
    '::communicationTemplateView'
);
subtest 'methods' => sub {

    # Do not run these tests...
    can_ok $at, $_ for sort qw[
        admin_emitModerationEvent admin_getModerationEvent admin_queryModerationEvents
        admin_updateAccountEmail admin_deleteAccount admin_enableAccountInvites admin_getRecord
        admin_queryModerationStatuses admin_updateAccountHandle admin_disableAccountInvites
        admin_getAccountInfo admin_getAccountsInfo admin_getRepo admin_searchRepos admin_updateSubjectStatus
        admin_disableInviteCodes admin_getInviteCodes admin_getSubjectStatus admin_sendEmail
        admin_createCommunicationTemplate admin_listCommunicationTemplates admin_updateCommunicationTemplate
        admin_deleteCommunicationTemplate
    ];
};
#
done_testing;
