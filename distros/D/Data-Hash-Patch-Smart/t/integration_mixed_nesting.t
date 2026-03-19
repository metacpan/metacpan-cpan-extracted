use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

my $old = {
    config => {
        servers => [
            { host => 'a', ports => [ 1, 2 ] },
            { host => 'b', ports => [ 3, 4 ] },
        ],
    },
};

my $new = {
    config => {
        servers => [
            { host => 'a', ports => [ 1, 2, 9 ] },
            { host => 'b', ports => [ 3, 4 ] },
            { host => 'c', ports => [ 5 ] },
        ],
    },
};

my $changes = diff($old, $new);

my $patched = patch($old, $changes);

is_deeply $patched, $new, 'deep mixed nesting round-trip works';

done_testing;
