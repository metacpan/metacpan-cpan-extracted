use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

my $data = { a => { b => 1 } };

my $changes = [
    { op => 'change', path => '/a/c', to => 2 },
];

eval { patch($data, $changes, strict => 1) };
like $@, qr/missing hash key 'c'/, 'strict mode catches missing key';

my $unordered = { items => [qw(a b c)] };

my $changes2 = [
    { op => 'remove', path => '/items/*', from => 'x' },
];

eval { patch($unordered, $changes2, strict => 1) };
like $@, qr/not found/, 'strict mode catches missing unordered value';

done_testing;
