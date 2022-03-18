
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoBOM 0.002

use Test::More 0.88;
use Test::BOM;

my @files = (
    'lib/API/MailboxOrg.pm',
    'lib/API/MailboxOrg/API/Account.pm',
    'lib/API/MailboxOrg/API/Backup.pm',
    'lib/API/MailboxOrg/API/Base.pm',
    'lib/API/MailboxOrg/API/Blacklist.pm',
    'lib/API/MailboxOrg/API/Capabilities.pm',
    'lib/API/MailboxOrg/API/Context.pm',
    'lib/API/MailboxOrg/API/Domain.pm',
    'lib/API/MailboxOrg/API/Hello.pm',
    'lib/API/MailboxOrg/API/Invoice.pm',
    'lib/API/MailboxOrg/API/Mail.pm',
    'lib/API/MailboxOrg/API/Mailinglist.pm',
    'lib/API/MailboxOrg/API/Passwordreset.pm',
    'lib/API/MailboxOrg/API/Spamprotect.pm',
    'lib/API/MailboxOrg/API/Test.pm',
    'lib/API/MailboxOrg/API/Utils.pm',
    'lib/API/MailboxOrg/API/Validate.pm',
    'lib/API/MailboxOrg/API/Videochat.pm',
    'lib/API/MailboxOrg/APIBase.pm',
    'lib/API/MailboxOrg/Types.pm',
    't/001_base.t',
    't/002_hello-world.t',
    't/types/001_hashref_restricted.t',
    't/types/002_boolean.t'
);

ok(file_hasnt_bom($_)) for @files;

done_testing;
