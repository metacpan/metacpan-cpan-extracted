use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

my $old = {
    a => 1,
    b => [ 10, 20, 30 ],
    c => { x => 1, y => 2 },
};

my $new = {
    a => 2,
    b => [ 10, 30, 40 ],
    c => { x => 1, y => 99 },
};

my $changes = diff($old, $new);

my $patched = patch($old, $changes);

is_deeply $patched, $new, 'round-trip diff → patch works';

# Reverse direction
my $reverse = diff($new, $old);
my $restored = patch($new, $reverse);

is_deeply $restored, $old, 'reverse round-trip patch → diff works';

done_testing;
