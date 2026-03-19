use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

my $data = {
    users => {
        alice => { password => 'old1', role => 'admin' },
        bob   => { password => 'old2', role => 'user'  },
    },
};

my $changes = [
    { op => 'change', path => '/users/*/password', to => 'XXX' },
];

my $patched = patch($data, $changes);

is_deeply $patched, {
    users => {
        alice => { password => 'XXX', role => 'admin' },
        bob   => { password => 'XXX', role => 'user'  },
    },
}, 'wildcard patching works in integration';

done_testing;
