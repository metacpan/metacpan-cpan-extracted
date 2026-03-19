use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff_yaml);

# Empty diff
my $yaml = diff_yaml({ a => 1 }, { a => 1 });

like $yaml, qr/^\Q--- []\E\s*$/s, 'empty diff produces empty YAML list';

# Simple change
$yaml = diff_yaml({ a => 1 }, { a => 2 });
like $yaml, qr/op:\s*change/, 'change op present';
like $yaml, qr/path:\s*\/a/,  'path present';
like $yaml, qr/from:\s*1/,    'old value present';
like $yaml, qr/to:\s*2/,      'new value present';

# Add
$yaml = diff_yaml({}, { a => 10 });
like $yaml, qr/op:\s*add/, 'add op present';
like $yaml, qr/value:\s*10/, 'value present';

# Remove
$yaml = diff_yaml({ a => 10 }, {});
like $yaml, qr/op:\s*remove/, 'remove op present';
like $yaml, qr/from:\s*10/,   'removed value present';

done_testing();
