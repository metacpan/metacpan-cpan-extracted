#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Path qw(mkpath);

use_ok('Chandra::HotReload');

# --- constructor ---
{
    my $hr = Chandra::HotReload->new;
    ok($hr, 'HotReload created');
    isa_ok($hr, 'Chandra::HotReload');
    is($hr->interval, 1.0, 'default interval is 1.0');
}

# --- constructor with interval ---
{
    my $hr = Chandra::HotReload->new(interval => 0.5);
    is($hr->interval, 0.5, 'custom interval');
}

# --- interval getter/setter ---
{
    my $hr = Chandra::HotReload->new;
    $hr->interval(2.0);
    is($hr->interval, 2.0, 'interval set to 2.0');
}

# --- watch a file ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "initial\n";
    close $fh;

    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($filename, sub { });
    my @paths = $hr->watched_paths;
    is(scalar @paths, 1, 'one watched path');
    is($paths[0], $filename, 'watched path correct');
}

# --- watch requires path ---
{
    my $hr = Chandra::HotReload->new;
    eval { $hr->watch(undef, sub { }) };
    like($@, qr/requires a path/, 'watch dies without path');
}

# --- watch requires callback ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;
    my $hr = Chandra::HotReload->new;
    eval { $hr->watch($filename, undef) };
    like($@, qr/requires a callback/, 'watch dies without callback');
}

# --- watch requires existing path ---
{
    my $hr = Chandra::HotReload->new;
    eval { $hr->watch('/nonexistent/path/xyz', sub { }) };
    like($@, qr/does not exist/, 'watch dies for nonexistent path');
}

# --- poll detects no changes ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "content\n";
    close $fh;

    my @changed_files;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($filename, sub { @changed_files = @{$_[0]} });

    my $result = $hr->poll;
    is($result, 0, 'poll returns 0 when no changes');
    is(scalar @changed_files, 0, 'callback not called');
}

# --- poll detects file modification ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "original\n";
    close $fh;

    my @changed_files;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($filename, sub { @changed_files = @{$_[0]} });

    # First poll to establish baseline
    $hr->poll;
    @changed_files = ();

    # Modify the file (need to change mtime)
    sleep 1; # ensure mtime changes
    open $fh, '>', $filename or die "Cannot write: $!";
    print $fh "modified\n";
    close $fh;

    my $result = $hr->poll;
    ok($result > 0, 'poll returns >0 when file changed');
    is(scalar @changed_files, 1, 'callback called with 1 changed file');
    is($changed_files[0], $filename, 'changed file is correct');
}

# --- poll detects new file in directory ---
{
    my $dir = tempdir(CLEANUP => 1);
    my $existing = "$dir/existing.txt";
    open my $fh, '>', $existing or die "Cannot write: $!";
    print $fh "hello\n";
    close $fh;

    my @changed_files;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { @changed_files = @{$_[0]} });

    # First poll
    $hr->poll;
    @changed_files = ();

    # Add a new file
    sleep 1;
    my $newfile = "$dir/new.txt";
    open $fh, '>', $newfile or die "Cannot write: $!";
    print $fh "new content\n";
    close $fh;

    my $result = $hr->poll;
    ok($result > 0, 'poll detects new file in directory');
    ok(scalar @changed_files >= 1, 'callback called for new file');
    ok(grep({ $_ eq $newfile } @changed_files), 'new file in changed list');
}

# --- poll detects deleted file ---
{
    my $dir = tempdir(CLEANUP => 1);
    my $file1 = "$dir/a.txt";
    my $file2 = "$dir/b.txt";
    for my $f ($file1, $file2) {
        open my $fh, '>', $f or die "Cannot write: $!";
        print $fh "data\n";
        close $fh;
    }

    my @changed_files;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { @changed_files = @{$_[0]} });

    $hr->poll;
    @changed_files = ();

    # Delete a file
    unlink $file2;

    my $result = $hr->poll;
    ok($result > 0, 'poll detects deleted file');
    ok(grep({ $_ eq $file2 } @changed_files), 'deleted file in changed list');
}

# --- interval throttling ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "data\n";
    close $fh;

    my $calls = 0;
    my $hr = Chandra::HotReload->new(interval => 10); # very long interval
    $hr->watch($filename, sub { $calls++ });

    $hr->poll; # first poll always runs
    my $result = $hr->poll; # should be throttled
    is($result, 0, 'second poll throttled by interval');
}

# --- multiple watches ---
{
    my ($fh1, $file1) = tempfile(UNLINK => 1);
    print $fh1 "a\n"; close $fh1;
    my ($fh2, $file2) = tempfile(UNLINK => 1);
    print $fh2 "b\n"; close $fh2;

    my ($cb1, $cb2) = (0, 0);
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($file1, sub { $cb1++ });
    $hr->watch($file2, sub { $cb2++ });

    my @paths = $hr->watched_paths;
    is(scalar @paths, 2, 'two watched paths');

    $hr->poll; # baseline

    sleep 1;
    open $fh1, '>', $file1 or die; print $fh1 "changed\n"; close $fh1;

    $hr->poll;
    is($cb1, 1, 'first watch callback called');
    is($cb2, 0, 'second watch callback not called');
}

# --- clear ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "data\n"; close $fh;

    my $hr = Chandra::HotReload->new;
    $hr->watch($filename, sub { });
    is(scalar $hr->watched_paths, 1, 'has watched path');

    $hr->clear;
    is(scalar $hr->watched_paths, 0, 'cleared all watches');
}

# --- callback error doesn't crash ---
{
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "data\n"; close $fh;

    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($filename, sub { die "callback crash" });

    $hr->poll; # baseline

    sleep 1;
    open $fh, '>', $filename or die; print $fh "changed\n"; close $fh;

    # Should warn but not die
    my $warning;
    local $SIG{__WARN__} = sub { $warning = $_[0] };
    eval { $hr->poll };
    ok(!$@, 'poll survives callback crash');
    like($warning, qr/callback error/, 'warning emitted for callback crash');
}

# --- watch directory recursively ---
{
    my $dir = tempdir(CLEANUP => 1);
    mkpath("$dir/sub");
    for my $f ("$dir/root.txt", "$dir/sub/deep.txt") {
        open my $fh, '>', $f or die; print $fh "x\n"; close $fh;
    }

    my @changed;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { @changed = @{$_[0]} });

    $hr->poll; # baseline
    @changed = ();

    sleep 1;
    open my $fh, '>', "$dir/sub/deep.txt" or die;
    print $fh "modified\n"; close $fh;

    $hr->poll;
    ok(scalar @changed >= 1, 'change detected in subdirectory');
    ok(grep({ /deep\.txt/ } @changed), 'deep file in changed list');
}

done_testing;
