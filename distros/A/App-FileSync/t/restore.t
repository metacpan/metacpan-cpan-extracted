use strict;
use warnings;
use Test::Most;
use Test::Exception;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;
use App::FileSync::Admin;
use App::FileSync::Snapshot;

my $T0 = 1_700_000_000;
my $filesync = File::Spec->catfile($Bin, '..', 'bin', 'filesync');
my $admin_bin = File::Spec->catfile($Bin, '..', 'bin', 'filesync-admin');

my $today = App::FileSync::Snapshot::date_for_epoch(time);

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    binmode $fh;
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

# -------------------------------------------------------- client trash
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "keep\n", $T0);
    $env->write_file('client', 'sub/b.txt', "nested\n", $T0 + 1);
    $env->sync();

    unlink $env->server_path('a.txt');
    unlink $env->server_path('sub/b.txt');
    my $deleted = $env->sync(force => 1);
    is($deleted->{summary}{deleted}, 2, 'both master deletions reach the client trash');
    ok(!$env->exists_in('client', 'a.txt'), 'the files are gone');

    my $list = $env->restore(path => 'a.txt', list => 1);
    is(scalar @{ $list->{versions} }, 1, 'one trashed version is listed');
    is($list->{versions}[0]{date}, $today, 'the version is dated today');
    like($list->{versions}[0]{path}, qr{trash[/\\].*[/\\]a\.txt\z},
        'the version path is reported');

    my $restored = $env->restore(path => 'a.txt');
    is($restored->{to}, $env->client_path('a.txt'), 'the file goes back where it was');
    is($env->read_file('client', 'a.txt'), "keep\n", 'content is restored');

    throws_ok { $env->restore(path => 'a.txt') } qr/Refusing to overwrite/,
        'an existing file is not overwritten';

    my $export = tempdir(CLEANUP => 1);
    my $nested = $env->restore(path => 'sub/b.txt', to => $export);
    is($nested->{to}, File::Spec->catfile($export, 'sub', 'b.txt'),
        '--to exports the original relative path');
    is(slurp("$export/sub/b.txt"), "nested\n", 'the exported copy has the content');

    throws_ok { $env->restore(path => 'nothere.txt') } qr/No trashed version/,
        'a path that was never trashed is an error';
}

# -------------------------------------------------- client restore CLI
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "restored\n", $T0);
    $env->sync();

    unlink $env->server_path('a.txt');
    $env->sync();

    my $output = `$^X $filesync restore a.txt --repo docs 2>&1`;
    is($?, 0, 'filesync restore exits 0');
    like($output, qr/Restored a\.txt to /, 'the restore reports the destination');
    is($env->read_file('client', 'a.txt'), "restored\n", 'the file is back');

    $output = `$^X $filesync restore a.txt --repo docs --list 2>&1`;
    is($?, 0, 'filesync restore --list exits 0');
    like($output, qr/$today/, 'the stored version is dated');

    $output = `$^X $filesync restore a.txt --repo docs 2>&1`;
    is($? >> 8, 1, 'restoring over an existing file fails');
    like($output, qr/Refusing to overwrite/, 'the failure explains why');

    $output = `$^X $filesync restore nothere.txt --repo docs 2>&1`;
    is($? >> 8, 1, 'restoring a path with no trash entry fails');
    like($output, qr/No trashed version/, 'the failure names the path');
}

# ----------------------------------------------------------- server trash
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "keep\n", $T0);
    $env->write_file('client', 'sub/b.txt', "nested\n", $T0 + 1);
    $env->sync();

    unlink $env->client_path('a.txt');
    unlink $env->client_path('sub/b.txt');
    $env->sync(force => 1);
    ok(!$env->exists_in('server', 'a.txt'), 'the master file is gone');

    my $admin = App::FileSync::Admin->new(root => $env->{server});

    my $list = $admin->restore(repo => 'docs', path => 'a.txt', list => 1);
    is(scalar @{ $list->{versions} }, 1, 'the server trash lists one version');
    is($list->{versions}[0]{date}, $today, 'it is dated today');

    my $restored = $admin->restore(repo => 'docs', path => 'a.txt');
    is($restored->{to}, $env->server_path('a.txt'), 'the file is restored into the master');
    is($env->read_file('server', 'a.txt'), "keep\n", 'the master content is back');
    ok($restored->{into_master}, 'the result says it went into the master');
    ok($restored->{sha256} =~ /\A[0-9a-f]{64}\z/, 'the restored hash is reported');

    ok($admin->verify(repo => 'docs')->{ok}, 'the index was rebuilt for the restored file');

    my $events = $admin->journal_read(repo => 'docs');
    my @restores = grep { ($_->{action} || '') eq 'restore' } @{ $events };
    is(scalar @restores, 1, 'the restore is journaled');
    is($restores[0]{path}, 'a.txt', 'the journal names the path');
    is($restores[0]{trash}, $restored->{from}, 'the journal names the trash entry');
    ok(!defined $restores[0]{client}, 'an admin restore has no client id');

    throws_ok { $admin->restore(repo => 'docs', path => 'a.txt') } qr/Refusing to overwrite/,
        'restoring over a master file is refused';

    my $export = tempdir(CLEANUP => 1);
    my $nested = $admin->restore(repo => 'docs', path => 'sub/b.txt', to => $export);
    is($nested->{to}, File::Spec->catfile($export, 'sub', 'b.txt'),
        '--to exports the original relative path');
    is(slurp("$export/sub/b.txt"), "nested\n", 'the export has the content');
    ok(!$nested->{into_master}, 'an export does not touch the master');

    throws_ok {
        $admin->restore(repo => 'docs', path => 'sub/b.txt', to => $export, date => '1999-01-01');
    } qr/No version of 'sub\/b\.txt'/, 'a date with nothing in it is an error';

    # The restored file is new to the client and is pulled on the next run.
    my $pull = $env->sync();
    is($pull->{summary}{pulled}, 1, 'the next client run pulls the restored file');
    is($env->read_file('client', 'a.txt'), "keep\n", 'the client has the restored content');
}

# -------------------------------------------------- admin restore CLI
{
    my $env = TestSync->new_env();
    $env->write_file('client', 'a.txt', "from the trash\n", $T0);
    $env->sync();

    unlink $env->client_path('a.txt');
    $env->sync();

    my $output = `$^X $admin_bin --root $env->{server} restore docs a.txt --list 2>&1`;
    is($?, 0, 'filesync-admin restore --list exits 0');
    like($output, qr/$today/, 'the version is dated');

    my $export = tempdir(CLEANUP => 1);
    $output = `$^X $admin_bin --root $env->{server} restore docs a.txt --to $export 2>&1`;
    is($?, 0, 'filesync-admin restore --to exits 0');
    like($output, qr/Restored docs:a\.txt/, 'the restore names the repo and path');
    is(slurp("$export/a.txt"), "from the trash\n", 'the exported content is right');

    $output = `$^X $admin_bin --root $env->{server} log docs -n 5 2>&1`;
    is($?, 0, 'filesync-admin log exits 0');
    like($output, qr/restore/, 'the restore appears in the journal');
    like($output, qr/trash=/, 'the journal line names the trash entry');

    $output = `$^X $admin_bin --root $env->{server} restore docs nothere.txt 2>&1`;
    is($? >> 8, 1, 'restoring a path with no trash entry fails');
    like($output, qr/No trashed version/, 'the failure names the path');
}

done_testing();
