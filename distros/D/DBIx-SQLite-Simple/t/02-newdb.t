use Test;
BEGIN { plan(tests => 1) }

require DBIx::SQLite::Simple;
my $db = DBIx::SQLite::Simple->new(db => 'test-file.db');

ok(1);
