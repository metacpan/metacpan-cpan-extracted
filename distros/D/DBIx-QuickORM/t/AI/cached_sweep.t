use Test2::V0;

# The cached row manager holds rows weakly and purges dead cache entries on a
# same-key collision. A workload that inserts an unending stream of distinct
# primary keys never re-hits a key, so without an amortized sweep the bucket
# accumulates one dead (undef) entry per row forever. Drive cache() directly
# with throwaway rows that fall out of scope immediately and assert the bucket
# stays bounded rather than growing ~1:1 with the number of rows.

use DBIx::QuickORM::RowManager::Cached;

package My::Mock::Source {
    sub new         { bless {}, shift }
    sub primary_key { ['id'] }
    sub source_orm_name { 'things' }
}

package My::Mock::Connection {
    sub new          { bless {}, shift }
    sub transactions { [] }
}

my $con    = My::Mock::Connection->new;
my $source = My::Mock::Source->new;
my $mgr    = DBIx::QuickORM::RowManager::Cached->new(connection => $con);

my $N = 2000;
for my $i (1 .. $N) {
    my $row = bless {}, 'My::Mock::Row';
    $mgr->cache($source, $row, undef, [$i]);
    # $row falls out of scope here; its weak entry in the bucket goes undef.
}

my $bucket = $mgr->{DBIx::QuickORM::RowManager::Cached->CACHE}->{'things'};
my $size   = scalar keys %$bucket;

ok($size < $N / 4, "cache bucket stays bounded ($size entries) for $N ever-new primary keys")
    or diag("bucket grew to $size entries for $N inserts - dead keys are not being swept");

done_testing;
