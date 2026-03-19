use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff);

# No changes
is_deeply diff({ a => 1 }, { a => 1 }), [],
    'identical structures produce no diff';

# Scalar change
is_deeply diff({ a => 1 }, { a => 2 }), [
    { op => 'change', path => '/a', from => 1, to => 2 }
], 'scalar change detected';

# Add key
is_deeply diff({ }, { a => 1 }), [
    { op => 'add', path => '/a', value => 1 }
], 'add detected';

# Remove key
is_deeply diff({ a => 1 }, { }), [
    { op => 'remove', path => '/a', from => 1 }
], 'remove detected';

# Nested
is_deeply diff({ x => { y => 1 } }, { x => { y => 2 } }), [
    { op => 'change', path => '/x/y', from => 1, to => 2 }
], 'nested change detected';

done_testing;
