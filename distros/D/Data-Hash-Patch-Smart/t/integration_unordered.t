use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

my $old = {
    items => [ qw(a b c) ],
};

my $new = {
    items => [ qw(c a d) ],
};

my $changes = diff($old, $new, arrays => 'unordered');

my $patched = patch($old, $changes);

is_deeply $patched, $new, 'unordered array round-trip works';

# Reverse
my $reverse = diff($new, $old, arrays => 'unordered');
my $restored = patch($new, $reverse);

is_deeply $restored, $old, 'unordered reverse round-trip works';

done_testing;
