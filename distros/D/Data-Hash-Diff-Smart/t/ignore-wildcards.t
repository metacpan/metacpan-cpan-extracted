use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff);

my $old = {
    foo => {
        x => { bar => 1 },
        y => { bar => 2 },
    },
    keep => 1,
};

my $new = {
    foo => {
        x => { bar => 10 },
        y => { bar => 20 },
    },
    keep => 1,
};

# Ignore /foo/*/bar
my $changes = diff($old, $new,
    ignore => ['/foo/*/bar']
);

is_deeply $changes, [], 'wildcard ignore suppresses nested changes';

# Ensure non-matching paths still diff
$changes = diff($old, { %$new, keep => 2 },
    ignore => ['/foo/*/bar']
);

is scalar(@$changes), 1, 'non-wildcard paths still diff';
is $changes->[0]{path}, '/keep', 'correct path diffed';

done_testing;
