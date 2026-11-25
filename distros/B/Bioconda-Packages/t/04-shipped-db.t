use strict;
use warnings;
use Test::More;
use Bioconda::Packages;

# Sanity-check the bundled database if it is present (it is skipped on a source
# checkout that has not yet run the maintainer build).
my $bp = eval { Bioconda::Packages->new };
plan skip_all => "No bundled database available: $@" unless $bp;

my %s = $bp->stats;
cmp_ok($s{total}, '>', 1000, 'bundled db has many packages');
like($bp->db_version, qr/^\d{4}\.\d{1,2}\.\d+$/, 'bundled db has a version string');
ok($bp->exists('samtools'), 'samtools present in bundled db');

my $p = $bp->get('samtools');
ok(defined $p->current_version, 'samtools has a version');
ok(scalar($p->dependencies('host')) >= 1, 'samtools has host deps');

# A well-known widely-used dependency should have reverse deps.
cmp_ok(scalar($bp->reverse_dependencies('zlib', kind => 'all')), '>', 10,
       'zlib has many reverse deps');

done_testing;
