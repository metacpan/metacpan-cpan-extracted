use strict;
use warnings;

use Test::More 0.88;
use Test::Deep;
use Path::Tiny 0.062;

plan skip_all => 'this test requires a built dist' if not -d 'inc';

my @found_files;
path('inc')->visit(
    sub { push @found_files, $_->stringify if -f },
    { recurse => 1 },
);

cmp_deeply(
    \@found_files,
    [ 'inc/ExtUtils/HasCompiler.pm' ],
    'only ExtUtils::HasCompiler is bundled, and nothing else!',
);

done_testing;
