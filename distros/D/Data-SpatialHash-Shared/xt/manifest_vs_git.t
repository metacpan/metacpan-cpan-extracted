use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'not a git checkout' unless -d '.git';
my @manifest = do { open my $fh, '<', 'MANIFEST' or die $!;
    map { /^(\S+)/ ? $1 : () } <$fh> };
my %m = map { $_ => 1 } @manifest;
ok $m{'sphash.h'}, 'MANIFEST has sphash.h';
ok $m{'Shared.xs'}, 'MANIFEST has Shared.xs';
ok $m{'lib/Data/SpatialHash/Shared.pm'}, 'MANIFEST has the .pm';
# every tracked file under these dirs (and *.xs/*.h/*.PL) should be in MANIFEST.
# eg/, xt/, bench/ are covered too so newly-added examples/author-tests/benches
# can't silently drift out of MANIFEST again (the Task 7-8 regression).
for my $f (`git ls-files t lib eg xt bench '*.xs' '*.h' '*.PL'`) {
    chomp $f; next unless length $f;
    ok $m{$f}, "MANIFEST includes tracked $f";
}
done_testing;
