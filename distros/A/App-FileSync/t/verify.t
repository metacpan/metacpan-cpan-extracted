use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync;
use App::FileSync::Admin;

my $T0 = 1_700_000_000;
my $filesync = File::Spec->catfile($Bin, '..', 'bin', 'filesync');
my $admin_bin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-admin');

# ------------------------------------------------------------ client verify
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->write_file('client', 'sub/b.txt', "bravo\n", $T0 + 1);
    $env->sync();

    my $clean = $env->verify();
    ok($clean->{ok}, 'a synced tree verifies clean');
    is($clean->{files}, 2, 'both files are counted');
    is(scalar @{ $clean->{modified} }, 0, 'nothing modified');
    is(scalar @{ $clean->{missing} }, 0, 'nothing missing');
    is(scalar @{ $clean->{extra} }, 0, 'nothing extra');
    is($clean->{rehashed}, 0, 'nothing needed hashing');

    $env->write_file('client', 'a.txt', "changed\n", $T0 + 100);
    my $drift = $env->verify();
    ok(!$drift->{ok}, 'a local edit is detected');
    is(scalar @{ $drift->{modified} }, 1, 'one file is modified');
    is($drift->{modified}[0]{p}, 'a.txt', 'the modified path is named');

    unlink $env->client_path('sub/b.txt');
    $env->write_file('client', 'new.txt', "new\n", $T0 + 200);

    my $both = $env->verify();
    is_deeply([ map { $_->{p} } @{ $both->{modified} } ], ['a.txt'], 'still one modified');
    is_deeply([ map { $_->{p} } @{ $both->{missing} } ], ['sub/b.txt'], 'the deleted file is missing');
    is_deeply([ map { $_->{p} } @{ $both->{extra} } ], [ 'new.txt', 'sub' ],
        'the new file is extra, and so is the directory emptied by the deletion');
}

# A change that keeps size and mtime is trusted unless --deep is given.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    $env->write_file('client', 'a.txt', "bravo\n", $T0 + 500);
    utime($T0, $T0, $env->client_path('a.txt'));

    my $shallow = $env->verify();
    ok($shallow->{ok}, 'a same-size, same-mtime edit is trusted by default');

    my $deep = $env->verify(deep => 1);
    ok(!$deep->{ok}, '--deep rehashes and finds it');
    is($deep->{modified}[0]{p}, 'a.txt', 'the changed file is named');
    is($deep->{trusted}, 0, '--deep trusts nothing');
}

# A repo that has never synced has no base to compare against.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);

    my $report = $env->verify();
    ok(!$report->{ok}, 'an unsynced tree is reported as drift');
    is($report->{known}, 0, 'there is no cached base');
    is_deeply([ map { $_->{p} } @{ $report->{extra} } ], ['a.txt'], 'every file is extra');

    my $output = `$^X $filesync verify --repo docs 2>&1`;
    is($? >> 8, 4, 'the CLI exits 4');
    like($output, qr/no cached base/, 'the CLI explains that there is no base yet');
}

# ------------------------------------------------------------- admin verify
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->write_file('client', 'b.txt', "bravo\n", $T0 + 1);
    $env->sync();

    my $admin = App::FileSync::Admin->new(root => $env->{server});

    my $clean = $admin->verify(repo => 'docs');
    ok($clean->{ok}, 'the master verifies clean against its index');
    is($clean->{files}, 2, 'both master files are seen');
    is($clean->{rehashed}, 0, 'a clean verify does not rehash');

    my $sampled = $admin->verify(repo => 'docs', sample => 1);
    ok($sampled->{ok}, 'a sampled verify passes');
    is($sampled->{sampled}, 1, 'one file was sampled');
    is($sampled->{rehashed}, 1, 'the sampled file was rehashed');

    $env->write_file('server', 'a.txt', "tampered\n", $T0 + 500);
    my $drift = $admin->verify(repo => 'docs');
    ok(!$drift->{ok}, 'a hand-edited master file is detected');
    is_deeply([ map { $_->{p} } @{ $drift->{modified} } ], ['a.txt'], 'the modified path is named');
    like($drift->{modified}[0]{expected}, qr/\A[0-9a-f]{64}\z/, 'the expected hash is reported');
}

{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->write_file('client', 'b.txt', "bravo\n", $T0 + 1);
    $env->sync();

    my $admin = App::FileSync::Admin->new(root => $env->{server});

    unlink $env->server_path('b.txt');
    $env->write_file('server', 'dropped-in.txt', "by hand\n", $T0 + 2);

    my $report = $admin->verify(repo => 'docs');
    is_deeply([ map { $_->{p} } @{ $report->{missing} } ], ['b.txt'], 'a missing master file is reported');
    is_deeply([ map { $_->{p} } @{ $report->{extra} } ], ['dropped-in.txt'],
        'a file that is not in the index is extra');
}

# A master file whose size and mtime were preserved is only found by --deep.
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $admin = App::FileSync::Admin->new(root => $env->{server});

    $env->write_file('server', 'a.txt', "bravo\n", $T0 + 500);
    utime($T0, $T0, $env->server_path('a.txt'));

    ok($admin->verify(repo => 'docs')->{ok}, 'the index is trusted by default');
    ok(!$admin->verify(repo => 'docs', deep => 1)->{ok}, '--deep finds the change');
}

# ------------------------------------------------------- verify exit codes
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $output = `$^X $filesync verify --repo docs 2>&1`;
    is($?, 0, 'filesync verify exits 0 when clean');
    like($output, qr/docs: clean/, 'the report says clean');

    $env->write_file('client', 'a.txt', "changed\n", $T0 + 100);

    $output = `$^X $filesync verify --repo docs 2>&1`;
    is($? >> 8, 4, 'filesync verify exits 4 on drift');
    like($output, qr/drift detected/, 'the report says there is drift');
    like($output, qr/^  modified: a\.txt$/m, 'the drift is listed');

    $output = `$^X $filesync verify --repo docs --json 2>&1`;
    is($? >> 8, 4, '--json still exits 4 on drift');
    my $decoded = App::FileSync::json_decode($output);
    is($decoded->{results}[0]{repo}, 'docs', 'the JSON names the repo');
    ok(!$decoded->{results}[0]{ok}, 'the JSON reports drift');
}

{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "alpha\n", $T0);
    $env->sync();

    my $admin = App::FileSync::Admin->new(root => $env->{server});

    my $output = `$^X $admin_bin --root $env->{server} verify docs 2>&1`;
    is($?, 0, 'filesync-admin verify exits 0 when clean');
    like($output, qr/docs: clean/, 'the admin report says clean');

    $output = `$^X $admin_bin --root $env->{server} verify docs --sample 1 2>&1`;
    is($?, 0, 'a sampled admin verify exits 0 when clean');
    like($output, qr/1 rehashed/, 'the sample is reported as rehashed');

    $env->write_file('server', 'a.txt', "tampered\n", $T0 + 500);

    $output = `$^X $admin_bin --root $env->{server} verify docs 2>&1`;
    is($? >> 8, 4, 'filesync-admin verify exits 4 on drift');
    like($output, qr/^  modified: a\.txt$/m, 'the modified file is listed');

    $output = `$^X $admin_bin --root $env->{server} verify docs --json 2>&1`;
    is($? >> 8, 4, 'the admin --json mode exits 4 too');
    like($output, qr/"ok":0/, 'the JSON reports drift');
}

done_testing();
