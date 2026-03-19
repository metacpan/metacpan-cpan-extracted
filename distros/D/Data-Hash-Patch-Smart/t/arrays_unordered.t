use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

# Old and new arrays with the same multiset of values in different orders,
# plus some additions/removals.
my $old = { items => [qw(a b b c)] };
my $new = { items => [qw(b c c d)] };

my $changes = diff($old, $new, array_mode => 'unordered');
my $patched = patch($old, $changes);

is_deeply $patched, $new, 'unordered array round-trip works';

done_testing;
