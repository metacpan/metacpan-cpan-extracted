use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync;
use App::FileSync::Config;

my $root = File::Spec->catdir($Bin, '..');
my $perl = $^X;
my $filesync = File::Spec->catfile($root, 'bin', 'filesync');
my $admin = File::Spec->catfile($root, 'bin', 'filesync-admin');

my $env = TestSync->new_env();
$env->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);

my $output = `$perl $filesync sync --repo docs 2>&1`;
is($?, 0, 'filesync sync exits 0');
like($output, qr/docs: pulled 0, pushed 1/, 'sync reports what it did');
like($output, qr/transfer: sent 6 B, received 0 B, 0 files by delta/,
    'sync accounts for the bytes it transferred');

$output = `$perl $filesync status --repo docs 2>&1`;
is($?, 0, 'status exits 0');
like($output, qr/transfer:  sent 6 B, received 0 B, 0 files by delta/,
    'status repeats the last run\'s transfer accounting');

$output = `$perl $filesync sync --repo docs 2>&1`;
is($?, 0, 'a second run exits 0');
like($output, qr/docs: pulled 0, pushed 0/, 'a second run has nothing to do');
like($output, qr/transfer: sent 0 B, received 0 B, 0 files by delta/,
    'a settled run reports no transfer');

$output = `$perl $filesync version 2>&1`;
is($?, 0, 'version exits 0');
like($output, qr/filesync \d/, 'version is printed');

$output = `$perl $filesync status --json 2>&1`;
is($?, 0, 'status exits 0');
like($output, qr/"repo":"docs"/, 'status is valid JSON mentioning the repo');

$output = `$perl $admin --root $env->{server} repo list 2>&1`;
is($?, 0, 'admin repo list exits 0');
like($output, qr/^docs$/m, 'the repo is listed');

$output = `$perl $filesync sync --repo nosuchrepo 2>&1`;
isnt($?, 0, 'an unknown repo is an error');
like($output, qr/No repo 'nosuchrepo'/, 'the error names the repo');

$output = `$perl $filesync sync --dry-run 2>&1`;
is($?, 0, 'a dry run with nothing to do exits 0');

# A cache written before byte accounting has no counters.  Status should keep
# reporting the run and the file count, without inventing a zero-byte transfer.
{
    my $old = TestSync->new_env();
    $old->write_file('client', 'a.txt', "alpha\n", 1_700_000_000);
    $old->sync();

    my $cache_path = File::Spec->catfile(
        App::FileSync::Config::home_dir(), 'cache', 'docs.json'
    );
    my $cache = App::FileSync::json_decode(App::FileSync::read_text($cache_path));
    delete $cache->{last_run}{summary}{bytes_sent};
    delete $cache->{last_run}{summary}{bytes_received};
    App::FileSync::write_atomic($cache_path, App::FileSync::json_encode($cache) . "\n");

    $output = `$perl $filesync status --repo docs 2>&1`;
    is($?, 0, 'status exits 0 with an old cache');
    like($output, qr/  last run:  /, 'the last run is still reported');
    like($output, qr/  files:     1/, 'the file count is still reported');
    unlike($output, qr/transfer:/, 'no transfer line is invented without byte counters');
}

done_testing();
