use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

my $old = { items => [qw(a b c d)] };
my $new = { items => [qw(a x c d e)] };

my $changes = diff($old, $new, array_mode => 'index');
my $patched = patch($old, $changes);

is_deeply $patched, $new, 'index-mode array round-trip works';

done_testing;
