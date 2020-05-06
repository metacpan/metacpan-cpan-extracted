use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/appexec',
    'lib/App/Env.pm',
    'lib/App/Env/Example.pm',
    'lib/App/Env/Null.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/alias.t',
    't/appexec.t',
    't/appid.t',
    't/badmodule.t',
    't/bin/appexec.pl',
    't/bin/appwhich',
    't/bin/capture.pl',
    't/cache.t',
    't/cache_sig.t',
    't/capture.t',
    't/clone.t',
    't/default.t',
    't/env.t',
    't/envstr.t',
    't/fatal.t',
    't/lib/App/Env/App1.pm',
    't/lib/App/Env/App2.pm',
    't/lib/App/Env/AppWhich.pm',
    't/lib/App/Env/Site.pm',
    't/lib/App/Env/Site1/App1.pm',
    't/lib/App/Env/Site1/App2.pm',
    't/lib/App/Env/Site1/App3.pm',
    't/lib/App/Env/Site1/App4.pm',
    't/lib/App/Env/Site2/App1.pm',
    't/null.t',
    't/regressions/capture_tiny.t',
    't/retrieve.t',
    't/setenv.t',
    't/site1.t',
    't/site2.t',
    't/site3.t',
    't/system.t',
    't/temp.t',
    't/use1.t',
    't/use2.t',
    't/use3.t',
    't/which.t'
);

notabs_ok($_) foreach @files;
done_testing;
