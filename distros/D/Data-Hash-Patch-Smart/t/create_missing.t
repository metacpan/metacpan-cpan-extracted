use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

my $data = {};

my $changes = [
    { op => 'add', path => '/a/b/2', value => 'X' },
];

my $patched = patch($data, $changes, create_missing => 1);

is_deeply $patched, {
    a => {
        b => [ undef, undef, 'X' ],
    }
}, 'auto-created nested hash and array';

# Now test mixed types
$data = {};

$changes = [
    { op => 'change', path => '/x/0/y', to => 123 },
];

$patched = patch($data, $changes, create_missing => 1);

is_deeply $patched, {
    x => [
        { y => 123 }
    ]
}, 'auto-created hash inside array inside hash';

done_testing;
