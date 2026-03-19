use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

# Create a cycle
my $x = {};
$x->{self} = $x;

my $changes = [
    { op => 'change', path => '/self/*/value', to => 'X' },
];

eval { patch($x, $changes, strict => 1) };

like $@, qr/Cycle detected/, 'cycle detection works during structural wildcard patch';

done_testing;
