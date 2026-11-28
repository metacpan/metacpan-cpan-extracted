# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Manual();

open(my $fh, '<', $INC{'DBIx/QuickORM/Manual.pm'}) or die "Could not read the manual index: $!";
my @pages = map { m/^L<(DBIx::QuickORM::Manual::[\w:]+)> - / ? $1 : () } <$fh>;

ok(scalar(@pages),       "The index lists pages");
ok(eval "require $_; 1", "$_ is there") || diag($@) for @pages;

done_testing;
