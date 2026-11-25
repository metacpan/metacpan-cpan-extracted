use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use JSON::PP;
use Bioconda::Packages::DB;
use Bioconda::Packages;

my $dir = tempdir(CLEANUP => 1);
my $path = File::Spec->catfile($dir, 'fixture.json');

my $data = {
    meta => {
        generated_at   => '2026-11-24T00:00:00Z',
        recipes_commit => 'deadbeef',
        package_count  => 3,
        removed_count  => 1,
    },
    packages => {
        samtools => {
            name => 'samtools', current_version => '1.25',
            summary => 'SAM/BAM/CRAM tools', license => 'MIT',
            noarch => undef, is_removed => JSON::PP::false,
            depends => { build => [], host => [{name=>'zlib'}], run => [{name=>'perl'}] },
            recipe_versions => ['1.24','1.25'],
        },
        multiqc => {
            name => 'multiqc', current_version => '1.35',
            summary => 'Aggregate bioinformatics results', license => 'GPL-3.0',
            noarch => 'python', is_removed => JSON::PP::false,
            depends => { build => [], host => [], run => [{name=>'python'},{name=>'zlib'}] },
        },
        oldtool => {
            name => 'oldtool', current_version => '0.1',
            summary => 'gone', license => 'MIT',
            is_removed => JSON::PP::true, removed_at => '2026-01-01T00:00:00Z',
            depends => { build => [], host => [], run => [{name=>'zlib'}] },
        },
    },
};
Bioconda::Packages::DB->save($path, $data);

my $bp = Bioconda::Packages->new(db => $path);
isa_ok($bp, 'Bioconda::Packages');

# exists / get
ok($bp->exists('samtools'),  'exists');
ok($bp->exists('SAMTOOLS'),  'exists is case-insensitive');
ok($bp->exists('oldtool'),   'removed package still exists');
ok(!$bp->exists('nope'),     'unknown package');

my $p = $bp->get('samtools');
isa_ok($p, 'Bioconda::Packages::Package');
is($p->current_version, '1.25', 'current_version');
is_deeply([$p->dependency_names('run')], ['perl'], 'run dep names');
is_deeply([$p->recipe_versions], ['1.24','1.25'], 'recipe_versions');
ok(!$p->is_removed, 'samtools not removed');

ok($bp->get('oldtool')->is_removed, 'oldtool flagged removed');
is($bp->get('oldtool')->removed_at, '2026-01-01T00:00:00Z', 'removed_at');

# list / count exclude removed by default
is_deeply([$bp->list], [qw(multiqc samtools)], 'list excludes removed');
is_deeply([$bp->list(include_removed => 1)], [qw(multiqc oldtool samtools)],
          'list include_removed');
is($bp->count, 2, 'count excludes removed');
is($bp->count(include_removed => 1), 3, 'count all');

# removed
is_deeply([$bp->removed], ['oldtool'], 'removed list');

# search
is_deeply([$bp->search('sam')], ['samtools'], 'search by name');
is_deeply([$bp->search('aggregate')], ['multiqc'], 'search by summary');
is_deeply([$bp->search('MIT', fields => ['license'])], ['samtools'],
          'search by explicit field excludes removed');
is_deeply([$bp->search('gone', include_removed => 1)], ['oldtool'],
          'search include_removed');

# reverse dependencies
is_deeply([$bp->reverse_dependencies('zlib', kind => 'all')],
          [qw(multiqc samtools)], 'reverse deps (all, excludes removed)');
is_deeply([$bp->reverse_dependencies('zlib', kind => 'run')],
          [qw(multiqc)], 'reverse deps run only');
is_deeply([$bp->reverse_dependencies('zlib', kind => 'all', include_removed => 1)],
          [qw(multiqc oldtool samtools)], 'reverse deps include removed');

# stats
my %s = $bp->stats;
is($s{total}, 3, 'stats total');
is($s{current}, 2, 'stats current');
is($s{removed}, 1, 'stats removed');
is($s{noarch}, 1, 'stats noarch');
is($s{recipes_commit}, 'deadbeef', 'stats commit');

done_testing;
