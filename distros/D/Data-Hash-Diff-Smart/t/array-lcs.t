use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff);

# LCS mode
my $old = [qw(a b c d)];
my $new = [qw(a x b c y d)];

my $changes = diff($old, $new, array_mode => 'lcs');

is scalar(@$changes), 2, 'two changes detected';

like $changes->[0]{op}, qr/add|change/, 'first op is add/change';
like $changes->[1]{op}, qr/add|change/, 'second op is add/change';

done_testing;
