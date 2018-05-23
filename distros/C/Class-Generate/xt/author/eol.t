use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Class/Generate.pm',
    't/00-compile.t',
    't/A_Class.pm',
    't/Test_Framework.pm',
    't/class_options.t',
    't/constructor.t',
    't/copy.t',
    't/equals.t',
    't/flags.t',
    't/functions.t',
    't/member_options.t',
    't/member_references.t',
    't/param_styles.t',
    't/protected_members.t',
    't/protected_methods.t',
    't/rt27445.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
