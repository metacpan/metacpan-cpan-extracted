use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/CanvasCloud.pm',
    'lib/CanvasCloud/API.pm',
    'lib/CanvasCloud/API/Account.pm',
    'lib/CanvasCloud/API/Account/OutcomeImport.pm',
    'lib/CanvasCloud/API/Account/Report.pm',
    'lib/CanvasCloud/API/Account/SISImport.pm',
    'lib/CanvasCloud/API/Account/Term.pm',
    'lib/CanvasCloud/API/Account/Users.pm',
    'lib/CanvasCloud/API/Courses.pm',
    'lib/CanvasCloud/API/Users.pm',
    'lib/CanvasCloud/API/Users/MissingSubmissions.pm',
    't/100-site-api.t',
    't/101-site-api-account.t',
    't/102-site-api-account-term.t',
    't/103-site-api-account-report.t',
    't/104-site-api-account-sisimport.t',
    't/105-site-api-account-outcomeimport.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
