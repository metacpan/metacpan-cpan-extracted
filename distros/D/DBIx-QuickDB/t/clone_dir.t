use Test2::V0;
use File::Temp qw/tempdir/;
use IPC::Cmd qw/can_run/;

use DBIx::QuickDB::Util;

my $RSYNC = can_run('rsync');
my $CP    = can_run('cp');
my $FCR   = eval { require File::Copy::Recursive; 1 };

sub make_src {
    my $src = tempdir(CLEANUP => 1);

    # Regular file
    open(my $fh, '>', "$src/file1") or die "$!";
    print $fh "hello\n";
    close($fh);

    # Subdirectory with a file
    mkdir "$src/subdir" or die "$!";
    open($fh, '>', "$src/subdir/file2") or die "$!";
    print $fh "world\n";
    close($fh);

    # Hidden file (dotfile)
    open($fh, '>', "$src/.hidden") or die "$!";
    print $fh "secret\n";
    close($fh);

    return $src;
}

sub check_dest {
    my ($dest, $label) = @_;

    ok(-f "$dest/file1", "$label: file1 exists at top level");
    ok(-f "$dest/subdir/file2", "$label: subdir/file2 exists");
    ok(-f "$dest/.hidden", "$label: dotfile copied");

    is(slurp("$dest/file1"), "hello\n", "$label: file1 content correct");
    is(slurp("$dest/subdir/file2"), "world\n", "$label: subdir/file2 content correct");
    is(slurp("$dest/.hidden"), "secret\n", "$label: dotfile content correct");

    # Must not nest the source directory inside dest
    opendir(my $dh, $dest) or die "$!";
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir($dh);
    is(
        [sort @entries],
        [sort qw/file1 subdir .hidden/],
        "$label: no extra entries in dest (no nested source dir)",
    );
}

sub slurp {
    open(my $fh, '<', $_[0]) or die "Could not open $_[0]: $!";
    local $/;
    return <$fh>;
}

subtest rsync => sub {
    skip_all "rsync not available" unless $RSYNC;

    my $src  = make_src();
    my $dest = tempdir(CLEANUP => 1);

    DBIx::QuickDB::Util::_clone_dir_rsync($src, $dest);
    check_dest($dest, 'rsync');
};

subtest cp => sub {
    skip_all "cp not available" unless $CP;

    my $src  = make_src();
    my $dest = tempdir(CLEANUP => 1);

    DBIx::QuickDB::Util::_clone_dir_cp($src, $dest);
    check_dest($dest, 'cp');
};

subtest fcr => sub {
    skip_all "File::Copy::Recursive not available" unless $FCR;

    my $src  = make_src();
    my $dest = tempdir(CLEANUP => 1);

    DBIx::QuickDB::Util::_clone_dir_fcr($src, $dest);
    check_dest($dest, 'fcr');
};

subtest rsync_overwrites_existing => sub {
    skip_all "rsync not available" unless $RSYNC;

    my $src  = make_src();
    my $dest = tempdir(CLEANUP => 1);

    # Pre-populate dest with a file that should be removed by --delete
    open(my $fh, '>', "$dest/stale") or die "$!";
    print $fh "old\n";
    close($fh);

    DBIx::QuickDB::Util::_clone_dir_rsync($src, $dest);
    check_dest($dest, 'rsync overwrite');
    ok(!-e "$dest/stale", "rsync overwrite: stale file removed");
};

subtest cp_overwrites_existing => sub {
    skip_all "cp not available" unless $CP;

    my $src  = make_src();
    my $dest = tempdir(CLEANUP => 1);

    # Pre-populate dest with a file that should be removed
    open(my $fh, '>', "$dest/stale") or die "$!";
    print $fh "old\n";
    close($fh);

    DBIx::QuickDB::Util::_clone_dir_cp($src, $dest);
    check_dest($dest, 'cp overwrite');
    ok(!-e "$dest/stale", "cp overwrite: stale file removed");
};

subtest fcr_overwrites_existing => sub {
    skip_all "File::Copy::Recursive not available" unless $FCR;

    my $src  = make_src();
    my $dest = tempdir(CLEANUP => 1);

    # Pre-populate dest with a file that should be removed
    open(my $fh, '>', "$dest/stale") or die "$!";
    print $fh "old\n";
    close($fh);

    DBIx::QuickDB::Util::_clone_dir_fcr($src, $dest);
    check_dest($dest, 'fcr overwrite');
    ok(!-e "$dest/stale", "fcr overwrite: stale file removed");
};

done_testing;
