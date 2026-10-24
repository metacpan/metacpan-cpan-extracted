use strict;
use warnings;
use Test::Most;

use File::Path qw(make_path);
use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

use App::FileSync;
use App::FileSync::Admin;
use App::FileSync::Lock;
use App::FileSync::Store;

my $T0 = 1_700_000_000;
my $admin_bin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-admin');

# A hand-repaired master no longer matches its index; reindex rebuilds it.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->write_file('client', 'sub/b.txt', "bravo\n", $T0 + 1);
    make_path($env->client_path('empty'));

    my $initial = $env->sync();
    is($initial->{summary}{pushed}, 3, 'the initial sync pushes the files and the empty dir');

    my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
    my $old   = $store->load_index();

    # Repair the master outside filesync: change one file, remove another,
    # drop a new file in and leave two directories empty.
    $env->write_file('server', 'a.txt', "alpha changed\n", $T0 + 100);
    unlink $env->server_path('sub/b.txt');
    $env->write_file('server', 'added.txt', "added\n", $T0 + 200);
    make_path($env->server_path('new-empty'));

    my $admin = App::FileSync::Admin->new(root => $env->{server});
    ok(!$admin->verify(repo => 'docs')->{ok},
        'the repaired master drifts from the old index');

    my $output = `$^X $admin_bin --root $env->{server} reindex docs --dry-run 2>&1`;
    is($?, 0, 'reindex --dry-run exits 0');
    like($output, qr/docs: would index 2 files, 3 empty dirs/,
        'the dry run counts the files and empty directories');
    like($output, qr/index unchanged/, 'and says the index was not written');
    is_deeply($store->load_index(), $old, 'the dry run leaves the index as it was');
    ok(!$admin->verify(repo => 'docs')->{ok}, 'the drift is still there');

    my @dry_events = grep { ($_->{action} || '') eq 'reindex' }
        @{ $admin->journal_read(repo => 'docs') };
    is(scalar @dry_events, 0, 'the dry run writes no journal entry');

    $output = `$^X $admin_bin --root $env->{server} reindex docs 2>&1`;
    is($?, 0, 'reindex exits 0');
    like($output, qr/docs: indexed 2 files, 3 empty dirs/,
        'the report counts what it indexed');
    like($output, qr/master index written/, 'and says the index was written');

    $output = `$^X $admin_bin --root $env->{server} reindex docs --dry-run --json 2>&1`;
    is($?, 0, 'reindex --json exits 0');
    my $json = App::FileSync::json_decode($output);
    is($json->{repo}, 'docs', 'the JSON names the repo');
    is($json->{files}, 2, 'the JSON carries the file count');
    is($json->{dirs}, 3, 'the JSON carries the empty-directory count');
    is($json->{dry_run}, 1, 'the JSON marks the dry run');
    is($json->{written}, 0, 'and says the index was not written');
    is_deeply($json->{skipped}, {}, 'the JSON has an empty skipped map');
    like($json->{index}, qr/master\.json\z/, 'the JSON names the index it would write');

    my $index = $store->load_index();
    is($index->{'a.txt'}{t}, 'f', 'the changed file is indexed as a file');
    isnt($index->{'a.txt'}{h}, $old->{'a.txt'}{h}, 'its new content has a new hash');
    ok($index->{'added.txt'}, 'the file dropped into the master is indexed');
    ok(!exists $index->{'sub/b.txt'}, 'the removed file is gone from the index');
    is_deeply($index->{'empty'}, { t => 'd' }, 'the empty directory is indexed');
    is_deeply($index->{'sub'}, { t => 'd' }, 'the directory emptied by the deletion is indexed');
    is_deeply($index->{'new-empty'}, { t => 'd' }, 'a newly empty directory is indexed');

    ok($admin->verify(repo => 'docs')->{ok}, 'verify is clean after reindex');
    ok($admin->verify(repo => 'docs', deep => 1)->{ok}, 'and --deep agrees');

    my @events = grep { ($_->{action} || '') eq 'reindex' }
        @{ $admin->journal_read(repo => 'docs') };
    is(scalar @events, 1, 'the reindex is journaled once');
    is($events[0]{files}, 2, 'the journal records the file count');
    is($events[0]{skipped}, 0, 'and that nothing was skipped');
}

# A reindex must not race a sync session.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $store  = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
    my $before = $store->load_index();

    my $lock = App::FileSync::Lock::acquire(
        path     => $store->lock_path(),
        nonblock => 1,
    );
    ok($lock, 'the test holds the repo lock');

    my $output = `$^X $admin_bin --root $env->{server} reindex docs 2>&1`;
    is($? >> 8, 1, 'reindex exits 1 while a session holds the lock');
    like($output, qr/holds the lock/, 'the refusal names the lock');

    is_deeply($store->load_index(), $before, 'the index was not replaced');
    undef $lock;
}

# Paths the scanner cannot index are reported rather than silently dropped.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $link = $env->server_path('link.txt');
    unless (eval { symlink $env->server_path('a.txt'), $link }) {
        skip 'symlinks are not available here', 8;
    } else {
        my $store = App::FileSync::Store->new(root => $env->{server}, repo => 'docs');
        my $admin = App::FileSync::Admin->new(root => $env->{server});

        my $result = $admin->reindex(repo => 'docs');
        is($result->{skipped}{'link.txt'}, 'symbolic link', 'the symlink is reported as skipped');
        ok(!exists $store->load_index()->{'link.txt'}, 'and is not in the index');

        my $output = `$^X $admin_bin --root $env->{server} reindex docs 2>&1`;
        is($?, 0, 'reindex still succeeds with a skipped path');
        like($output, qr/skipped: link\.txt \(symbolic link\)/,
            'the CLI names the skipped path');

        $output = `$^X $admin_bin --root $env->{server} reindex docs --json 2>&1`;
        is($?, 0, 'the JSON mode also succeeds with a skipped path');
        my $json = App::FileSync::json_decode($output);
        is($json->{skipped}{'link.txt'}, 'symbolic link',
            'the JSON carries the skipped path and reason');
        is($json->{files}, 1, 'the JSON counts the indexed file');
        ok($json->{written}, 'the JSON records that the index was written');
    }
}

done_testing();
