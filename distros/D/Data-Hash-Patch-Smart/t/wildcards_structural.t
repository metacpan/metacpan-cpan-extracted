use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

my $old = {
    users => {
        alice => { password => 'old1', role => 'admin' },
        bob   => { password => 'old2', role => 'user'  },
    },
};

my $changes = [
    { op => 'change', path => '/users/*/password', to => 'XXX' },
];

my $patched = patch($old, $changes);

is_deeply $patched, {
    users => {
        alice => { password => 'XXX', role => 'admin' },
        bob   => { password => 'XXX', role => 'user'  },
    },
}, 'structural wildcard change works';

done_testing;
