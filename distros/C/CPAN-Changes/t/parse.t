use strict;
use warnings;
use Test::More;

use CPAN::Changes::Parser;

my $parser = CPAN::Changes::Parser->new;

my $changes = $parser->parse_file('corpus/dists/DBIx-Class.changes');

is $changes->preamble, 'Revision history for DBIx::Class';
is scalar @{[ $changes->releases ]}, 114;

my $release = $changes->find_release(0.08260);

ok $release;

is_deeply [ map { $_->text } @{ $release->entries } ], [
  'New Features',
  'Notable Changes and Deprecations',
  'Fixes',
  'Misc',
];

$release = $changes->find_release(0.08250);
my $entry = $release
  ->find_entry('New Features / Changes')
  ->find_entry(qr/^Rewrite from scratch the result/);

ok $entry;

is scalar @{ $entry->entries }, 7;

ok $changes->find_release('v0.82.600');
ok $changes->find_release('0.82.600');
ok $changes->find_release('0.82.600');
ok $changes->find_release(0.08099_08);
ok $changes->find_release("0.08099_08");

done_testing;
