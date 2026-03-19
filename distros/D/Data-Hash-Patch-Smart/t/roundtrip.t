use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

my $old = {
    user => {
        name => 'Nigel',
        age  => 40,
    },
    tags => [qw(a b c)],
};

my $new = {
    user => {
        name => 'N. Horne',
        age  => 41,
    },
    tags => [qw(a x c d)],
};

my $changes = diff($old, $new);          # existing module
my $patched = patch($old, $changes);     # new module

is_deeply $patched, $new, 'round-trip diff + patch matches new';

done_testing;
