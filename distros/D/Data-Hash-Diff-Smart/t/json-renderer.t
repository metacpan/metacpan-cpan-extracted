use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff_json);

# Empty diff
is diff_json({ a => 1 }, { a => 1 }), '[]',
    'empty diff produces empty JSON array';

# Simple change
my $json = diff_json({ a => 1 }, { a => 2 });
like $json, qr/"op":"change"/, 'change op present';
like $json, qr/"path":"\/a"/,  'path present';
like $json, qr/"from":1/,      'old value present';
like $json, qr/"to":2/,        'new value present';

# Add
$json = diff_json({}, { a => 10 });
like $json, qr/"op":"add"/, 'add op present';
like $json, qr/"value":10/, 'value present';

# Remove
$json = diff_json({ a => 10 }, {});
like $json, qr/"op":"remove"/, 'remove op present';
like $json, qr/"from":10/,     'removed value present';

done_testing;

