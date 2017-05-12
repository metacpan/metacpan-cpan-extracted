use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Catalyst/Controller/ActionRole.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/action-class.t',
    't/basic.t',
    't/basic_rest.t',
    't/execution-via-config.t',
    't/execution-via-does.t',
    't/lib/Catalyst/Action/TestActionClass.pm',
    't/lib/Catalyst/ActionRole/Moo.pm',
    't/lib/Catalyst/ActionRole/Zoo.pm',
    't/lib/Moo.pm',
    't/lib/TestApp.pm',
    't/lib/TestApp/ActionRole/Boo.pm',
    't/lib/TestApp/ActionRole/First.pm',
    't/lib/TestApp/ActionRole/Kooh.pm',
    't/lib/TestApp/ActionRole/Moo.pm',
    't/lib/TestApp/ActionRole/Second.pm',
    't/lib/TestApp/ActionRole/Shared.pm',
    't/lib/TestApp/Controller/ActionClass.pm',
    't/lib/TestApp/Controller/Bar.pm',
    't/lib/TestApp/Controller/Boo.pm',
    't/lib/TestApp/Controller/ExecutionViaConfig.pm',
    't/lib/TestApp/Controller/ExecutionViaDoes.pm',
    't/lib/TestApp/Controller/Foo.pm',
    't/lib/TestAppREST.pm',
    't/lib/TestAppREST/ActionRole/Moo.pm',
    't/lib/TestAppREST/Controller/Foo.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
