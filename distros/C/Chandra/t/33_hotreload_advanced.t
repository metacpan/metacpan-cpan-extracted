#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Path qw(mkpath);

use_ok('Chandra::HotReload');

# === watch requires path ===
{
    my $hr = Chandra::HotReload->new;
    eval { $hr->watch(undef, sub { }) };
    like($@, qr/requires a path/, 'watch without path dies');
}

# === watch requires callback ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my $hr = Chandra::HotReload->new;
    eval { $hr->watch($f, undef) };
    like($@, qr/requires a callback/, 'watch without callback dies');
}

# === watch requires coderef ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my $hr = Chandra::HotReload->new;
    eval { $hr->watch($f, 'not a sub') };
    like($@, qr/requires a callback/, 'watch with non-coderef dies');
}

# === watch with non-existent path dies ===
{
    my $hr = Chandra::HotReload->new;
    eval { $hr->watch('/nonexistent/path/for/test', sub { }) };
    like($@, qr/does not exist/, 'watch with non-existent path dies');
}

# === new file detection ===
{
    my $dir = tempdir(CLEANUP => 1);

    my @changed;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { @changed = @{$_[0]} });

    $hr->poll; # baseline (empty dir)
    @changed = ();

    # Create a new file
    sleep 1;
    open my $fh, '>', "$dir/newfile.txt" or die;
    print $fh "new\n"; close $fh;

    $hr->poll;
    ok(scalar @changed >= 1, 'new file detected');
    ok(grep({ /newfile\.txt/ } @changed), 'new file in changed list');
}

# === deleted file detection ===
{
    my $dir = tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/deleteme.txt" or die;
    print $fh "data\n"; close $fh;

    my @changed;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { @changed = @{$_[0]} });

    $hr->poll; # baseline
    @changed = ();

    unlink "$dir/deleteme.txt";

    $hr->poll;
    ok(scalar @changed >= 1, 'deleted file detected');
    ok(grep({ /deleteme\.txt/ } @changed), 'deleted file in changed list');
}

# === callback error is caught and warned ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($f, sub { die "callback crash" });

    $hr->poll; # baseline

    sleep 1;
    open $fh, '>', $f or die;
    print $fh "changed\n"; close $fh;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $result = $hr->poll;
    ok(scalar @warnings >= 1, 'callback error warned');
    like($warnings[0], qr/callback error.*callback crash/, 'warning includes error message');
    ok($result >= 1, 'poll still returns changed count despite error');
}

# === poll returns 0 when throttled ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my $hr = Chandra::HotReload->new(interval => 100); # very long interval
    $hr->watch($f, sub { });

    $hr->poll; # first poll goes through
    my $result = $hr->poll; # should be throttled
    is($result, 0, 'second immediate poll returns 0 when throttled');
}

# === default interval is 1.0 ===
{
    my $hr = Chandra::HotReload->new;
    is($hr->interval, 1.0, 'default interval is 1.0');
}

# === multiple watches with different callbacks ===
{
    my $dir1 = tempdir(CLEANUP => 1);
    my $dir2 = tempdir(CLEANUP => 1);
    open my $fh1, '>', "$dir1/a.txt" or die;
    print $fh1 "a\n"; close $fh1;
    open my $fh2, '>', "$dir2/b.txt" or die;
    print $fh2 "b\n"; close $fh2;

    my (@changed1, @changed2);
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir1, sub { @changed1 = @{$_[0]} });
    $hr->watch($dir2, sub { @changed2 = @{$_[0]} });

    $hr->poll; # baseline
    @changed1 = ();
    @changed2 = ();

    sleep 1;
    open $fh1, '>', "$dir1/a.txt" or die;
    print $fh1 "modified a\n"; close $fh1;

    $hr->poll;
    ok(scalar @changed1 >= 1, 'first watch callback fired');
    is(scalar @changed2, 0, 'second watch callback not fired');
}

# === poll returns total changed files across watches ===
{
    my $dir1 = tempdir(CLEANUP => 1);
    my $dir2 = tempdir(CLEANUP => 1);
    open my $fh1, '>', "$dir1/a.txt" or die; print $fh1 "a\n"; close $fh1;
    open my $fh2, '>', "$dir2/b.txt" or die; print $fh2 "b\n"; close $fh2;

    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir1, sub { });
    $hr->watch($dir2, sub { });

    $hr->poll; # baseline

    sleep 1;
    open $fh1, '>', "$dir1/a.txt" or die; print $fh1 "a2\n"; close $fh1;
    open $fh2, '>', "$dir2/b.txt" or die; print $fh2 "b2\n"; close $fh2;

    my $total = $hr->poll;
    is($total, 2, 'poll returns total changed files across all watches');
}

# === watching a single file ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "original\n"; close $fh;

    my @changed;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($f, sub { @changed = @{$_[0]} });

    $hr->poll; # baseline
    @changed = ();

    sleep 1;
    open $fh, '>', $f or die;
    print $fh "modified\n"; close $fh;

    $hr->poll;
    ok(scalar @changed >= 1, 'single file change detected');
    is($changed[0], $f, 'changed file is the watched file');
}

done_testing;
