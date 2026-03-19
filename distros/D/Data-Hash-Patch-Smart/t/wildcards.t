use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart  qw(diff);
use Data::Hash::Patch::Smart qw(patch);

my $old = {
    users => {
        alice => { password => 'old1', role => 'admin' },
        bob   => { password => 'old2', role => 'user'  },
    },
};

my $new = {
    users => {
        alice => { password => 'new1', role => 'admin' },
        bob   => { password => 'new2', role => 'user'  },
    },
};

# Ignore roles, only diff passwords
my $changes = diff($old, $new, ignore => ['/users/*/role']);

my $patched = patch($old, $changes);

is_deeply $patched, $new, 'wildcard patching works';

done_testing;
