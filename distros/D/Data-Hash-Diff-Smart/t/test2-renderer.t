use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff_test2);

# Empty diff
is diff_test2({ a => 1 }, { a => 1 }), '',
    'empty diff produces empty diagnostics';

# Simple change
my $diag = diff_test2({ a => 1 }, { a => 2 });
like $diag, qr/# Difference at \/a/, 'change path shown';
like $diag, qr/#\s+- 1/,            'old value shown';
like $diag, qr/#\s+\+ 2/,           'new value shown';

# Add
$diag = diff_test2({}, { a => 10 });
like $diag, qr/# Added at \/a/, 'add path shown';
like $diag, qr/#\s+\+ 10/,      'added value shown';

# Remove
$diag = diff_test2({ a => 10 }, {});
like $diag, qr/# Removed at \/a/, 'remove path shown';
like $diag, qr/#\s+- 10/,         'removed value shown';

done_testing;
