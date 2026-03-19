use strict;
use warnings;
use Test::More;

use Data::Hash::Diff::Smart qw(diff);

my $old = [qw(a b b c)];
my $new = [qw(b c c d)];

my $changes = diff($old, $new, array_mode => 'unordered');

my %ops;
$ops{$_->{op}}++ for @$changes;

is $ops{add},    2, 'two adds';
is $ops{remove}, 2, 'two removes';

done_testing;
