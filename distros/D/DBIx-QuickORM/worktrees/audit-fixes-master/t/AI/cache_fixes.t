use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Exercises the cached row manager: composite cache keys with separator and
# backslash characters in the values, undef primary-key components (rows are
# skipped, not mis-keyed), uncache falling back to the row's ordered primary
# key values, and purging of dead weak cache entries.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/cache.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

my $sep = chr(31);

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE pairs (k1 TEXT NOT NULL, k2 TEXT NOT NULL, val TEXT, PRIMARY KEY (k1, k2))');
    $dbh->do('CREATE TABLE solo (solo_id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->disconnect;
}

my $con     = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $h       = $con->handle('pairs');
my $manager = $con->manager;

subtest composite_keys_with_separator_and_backslash => sub {
    my $row_a = $h->insert({k1 => "a${sep}b", k2 => "c",        val => 'A'});
    my $row_b = $h->insert({k1 => "a",        k2 => "b${sep}c", val => 'B'});
    my $row_c = $h->insert({k1 => "x\\",      k2 => "${sep}y",  val => 'C'});
    my $row_d = $h->insert({k1 => "x\\${sep}", k2 => "y",       val => 'D'});

    my $key_a = $manager->cache_key(["a${sep}b", "c"]);
    my $key_b = $manager->cache_key(["a", "b${sep}c"]);
    my $key_c = $manager->cache_key(["x\\", "${sep}y"]);
    my $key_d = $manager->cache_key(["x\\${sep}", "y"]);

    isnt($key_a, $key_b, "separator inside a value does not collide with the joined form");
    isnt($key_c, $key_d, "backslash before a separator does not collide with an escaped separator");

    ref_is($h->by_id({k1 => "a${sep}b", k2 => "c"}),        $row_a, "row A found under its own key");
    ref_is($h->by_id({k1 => "a",        k2 => "b${sep}c"}), $row_b, "row B found under its own key");
    ref_is($h->by_id({k1 => "x\\",      k2 => "${sep}y"}),  $row_c, "row C found under its own key");
    ref_is($h->by_id({k1 => "x\\${sep}", k2 => "y"}),       $row_d, "row D found under its own key");
};

subtest undef_pk_components_are_not_cached => sub {
    is($manager->cache_key([undef]), undef, "cache_key returns undef for an undef component");
    is($manager->cache_key(['a', undef]), undef, "any undef component disqualifies the key");

    my $source = $con->source('solo');
    my $row    = $con->handle('solo')->insert({name => 'fine'});

    my $bucket = $manager->{cache}{$source->source_orm_name};
    my $keys_before = keys %$bucket;

    my $warnings = warnings {
        my $ret = $manager->cache($source, $row, undef, [undef]);
        ref_is($ret, $row, "cache() returns the row unchanged for an unkeyable pk");
    };
    ok(!@$warnings, "no undef warnings from an undef pk component") or diag join "\n" => @$warnings;

    is(scalar keys %$bucket, $keys_before, "nothing was added to the cache bucket");

    ok(!$manager->do_cache_lookup($source, undef, [undef], undef), "do_cache_lookup with an undef component misses cleanly");
    ok(lives { $manager->uncache($source, undef, [undef], undef) }, "uncache with an undef component is a no-op");
};

subtest uncache_falls_back_to_ordered_pk_values => sub {
    my $row = $h->insert({k1 => 'unc1', k2 => 'unc2', val => 'U'});

    my $source = $con->source('pairs');
    my $got = $manager->uncache($source, $row);
    ref_is($got, $row, "uncache derived the composite key from the row itself");

    ok(!$con->state_cache_lookup('pairs', {k1 => 'unc1', k2 => 'unc2'}), "row is no longer cached");
};

subtest dead_weak_entries_are_purged => sub {
    my $source = $con->source('solo');
    my $sh     = $con->handle('solo');

    my @rows = map { $sh->insert({name => "purge_$_"}) } 1 .. 5;
    my @pks  = map { $_->field('solo_id') } @rows;

    my $bucket = $manager->{cache}{$source->source_orm_name};
    ok((grep { defined $bucket->{$_} } keys %$bucket) >= 5, "all five rows are cached and alive");

    @rows = ();    # Drop the only strong references; weak cache entries go undef.

    my $dead = grep { !defined $bucket->{$_} } keys %$bucket;
    ok($dead >= 5, "dead entries linger in the bucket before a purge");

    # A lookup that hits a dead entry triggers the purge.
    my $miss = $manager->do_cache_lookup($source, undef, [$pks[0]], undef);
    ok(!$miss, "lookup of a garbage-collected row misses");

    is((scalar grep { !defined $bucket->{$_} } keys %$bucket), 0, "all dead entries were purged from the bucket");
};

done_testing;
