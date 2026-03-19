use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff diff_text);

sub normalize {
    my ($s) = @_;
    $s =~ s/\s+$//;
    return $s;
}

# Empty diff
is normalize(diff_text({ a => 1 }, { a => 1 })), '',
    'empty diff produces empty text';

# Simple change
my $txt = diff_text({ a => 1 }, { a => 2 });
like $txt, qr/~ \/a/, 'change shows path';
like $txt, qr/- 1/,   'old value shown';
like $txt, qr/\+ 2/,  'new value shown';

# Add
$txt = diff_text({ }, { a => 10 });
like $txt, qr/\+ \/a/, 'add shows path';

# Remove
$txt = diff_text({ a => 10 }, { });
like $txt, qr/- \/a/, 'remove shows path';

done_testing;
