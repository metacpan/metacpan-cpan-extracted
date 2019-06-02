use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/2base',
    'bin/2u',
    'bin/NFC',
    'bin/NFD',
    'bin/artype',
    'bin/ascii',
    'bin/byte',
    'bin/filter_example_echo',
    'bin/hz',
    'bin/texize',
    'bin/unac',
    'bin/unpt',
    'bin/untashkeel',
    'lib/App/FilterUtils.pm',
    'lib/App/FilterUtils/2base.pm',
    'lib/App/FilterUtils/2u.pm',
    'lib/App/FilterUtils/NFC.pm',
    'lib/App/FilterUtils/NFD.pm',
    'lib/App/FilterUtils/artype.pm',
    'lib/App/FilterUtils/ascii.pm',
    'lib/App/FilterUtils/byte.pm',
    'lib/App/FilterUtils/filter_example_echo.pm',
    'lib/App/FilterUtils/hz.pm',
    'lib/App/FilterUtils/texize.pm',
    'lib/App/FilterUtils/unac.pm',
    'lib/App/FilterUtils/unpt.pm',
    'lib/App/FilterUtils/untashkeel.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/t/01-use-ok.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
