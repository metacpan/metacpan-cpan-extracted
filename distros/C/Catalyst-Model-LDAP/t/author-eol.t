
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Helper/Model/LDAP.pm',
    'lib/Catalyst/Model/LDAP.pm',
    'lib/Catalyst/Model/LDAP/Connection.pm',
    'lib/Catalyst/Model/LDAP/Entry.pm',
    'lib/Catalyst/Model/LDAP/Search.pm',
    't/01use.t',
    't/02pod.t',
    't/03podcoverage.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/lib/TestApp.pm',
    't/lib/TestApp/Controller/Root.pm',
    't/lib/TestApp/LDAP/Connection.pm',
    't/lib/TestApp/LDAP/Entry.pm',
    't/lib/TestApp/Model/LDAP.pm',
    't/lib/TestAppInheritedComponent.pm',
    't/lib/TestAppInheritedComponent/Controller/Root.pm',
    't/lib/TestAppInheritedComponent/Model/LDAP.pm',
    't/lib/TestAppInheritedComponent/Model/LDAP/Connection.pm',
    't/lib/TestAppInheritedComponent/Model/LDAP/Entry.pm',
    't/live_inherited_component.t',
    't/live_search.t',
    't/unit_Connection.t',
    't/unit_Connection_bind.t',
    't/unit_Connection_search.t',
    't/unit_Connection_search_limit.t',
    't/unit_Entry.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
