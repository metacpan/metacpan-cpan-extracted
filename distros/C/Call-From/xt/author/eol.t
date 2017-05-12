use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = ( 'lib/Call/From.pm', );

eol_unix_ok( $_, { trailing_whitespace => 1 } ) foreach @files;
done_testing;
