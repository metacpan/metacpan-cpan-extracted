
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/BZ/Client.pm',
    'lib/BZ/Client/API.pm',
    'lib/BZ/Client/Bug.pm',
    'lib/BZ/Client/Bug/Attachment.pm',
    'lib/BZ/Client/Bug/Comment.pm',
    'lib/BZ/Client/BugUserLastVisit.pm',
    'lib/BZ/Client/Bugzilla.pm',
    'lib/BZ/Client/Classification.pm',
    'lib/BZ/Client/Component.pm',
    'lib/BZ/Client/Exception.pm',
    'lib/BZ/Client/FlagType.pm',
    'lib/BZ/Client/Group.pm',
    'lib/BZ/Client/Product.pm',
    'lib/BZ/Client/User.pm',
    'lib/BZ/Client/XMLRPC.pm',
    'lib/BZ/Client/XMLRPC/Array.pm',
    'lib/BZ/Client/XMLRPC/Handler.pm',
    'lib/BZ/Client/XMLRPC/Parser.pm',
    'lib/BZ/Client/XMLRPC/Response.pm',
    'lib/BZ/Client/XMLRPC/Struct.pm',
    'lib/BZ/Client/XMLRPC/Value.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001load.t',
    't/010parser.t',
    't/011writer.t',
    't/100bugzilla.t',
    't/101login.t',
    't/200bug.t',
    't/300classification.t',
    't/400component.t',
    't/500group.t',
    't/600product.t',
    't/700user.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-breakpoints.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/lib/BZ/Client/Test.pm',
    't/release-distmeta.t',
    't/release-kwalitee.t',
    't/release-unused-vars.t',
    't/servers.cfg',
    't/write-config.pl'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
