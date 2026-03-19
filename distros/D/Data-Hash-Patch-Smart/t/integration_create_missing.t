use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

my $data = {};

my $changes = [
    { op => 'change', path => '/a/b/2', to => 'X' },
];

my $patched = patch($data, $changes, create_missing => 1);

is_deeply $patched, {
    a => {
        b => [ undef, undef, 'X' ],
    }
}, 'create_missing integration works';

done_testing;
