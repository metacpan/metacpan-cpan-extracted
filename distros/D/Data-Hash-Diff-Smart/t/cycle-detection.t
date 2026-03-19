use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff);

# Create a cycle
my $a = { value => 1 };
$a->{self} = $a;

my $b = { value => 2 };
$b->{self} = $b;

my $changes = diff($a, $b);

# Should detect the change in 'value'
is scalar(@$changes), 1, 'only one change detected';
is $changes->[0]{path}, '/value', 'correct path diffed';

done_testing;
