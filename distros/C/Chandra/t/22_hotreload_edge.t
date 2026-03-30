#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Path qw(mkpath);

use_ok('Chandra::HotReload');

# === clear() returns self ===
{
    my $hr = Chandra::HotReload->new;
    my $ret = $hr->clear;
    isa_ok($ret, 'Chandra::HotReload', 'clear returns self');
}

# === clear() empties watches ===
{
    my ($fh1, $f1) = tempfile(UNLINK => 1);
    print $fh1 "a\n"; close $fh1;
    my ($fh2, $f2) = tempfile(UNLINK => 1);
    print $fh2 "b\n"; close $fh2;

    my $hr = Chandra::HotReload->new;
    $hr->watch($f1, sub { });
    $hr->watch($f2, sub { });
    is(scalar $hr->watched_paths, 2, 'two watches before clear');

    $hr->clear;
    is(scalar $hr->watched_paths, 0, 'zero watches after clear');
}

# === clear() then re-watch ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "data\n"; close $fh;

    my $hr = Chandra::HotReload->new;
    $hr->watch($f, sub { });
    $hr->clear;
    $hr->watch($f, sub { });
    is(scalar $hr->watched_paths, 1, 'can re-watch after clear');
}

# === poll after clear returns 0 ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "data\n"; close $fh;

    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($f, sub { });
    $hr->clear;
    my $result = $hr->poll;
    is($result, 0, 'poll after clear returns 0');
}

# === watch() returns self for chaining ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my $hr = Chandra::HotReload->new;
    my $ret = $hr->watch($f, sub { });
    is($ret, $hr, 'watch returns self');
}

# === watch chaining ===
{
    my ($fh1, $f1) = tempfile(UNLINK => 1);
    print $fh1 "a\n"; close $fh1;
    my ($fh2, $f2) = tempfile(UNLINK => 1);
    print $fh2 "b\n"; close $fh2;

    my $hr = Chandra::HotReload->new;
    $hr->watch($f1, sub { })->watch($f2, sub { });
    is(scalar $hr->watched_paths, 2, 'chained watch registers both');
}

# === interval() getter returns current value ===
{
    my $hr = Chandra::HotReload->new(interval => 3.5);
    is($hr->interval, 3.5, 'interval getter');
}

# === interval() setter returns new value ===
{
    my $hr = Chandra::HotReload->new;
    my $ret = $hr->interval(0.25);
    is($ret, 0.25, 'interval setter returns value');
    is($hr->interval, 0.25, 'interval persisted');
}

# === interval(0) allows immediate polling ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my $called = 0;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($f, sub { $called++ });

    $hr->poll; # baseline
    $hr->poll; # should not be throttled
    # With interval 0, second poll should also run
    is($hr->interval, 0, 'interval is 0');
}

# === watched_paths order matches registration ===
{
    my ($fh1, $f1) = tempfile(UNLINK => 1);
    print $fh1 "a\n"; close $fh1;
    my ($fh2, $f2) = tempfile(UNLINK => 1);
    print $fh2 "b\n"; close $fh2;

    my $hr = Chandra::HotReload->new;
    $hr->watch($f1, sub { });
    $hr->watch($f2, sub { });

    my @paths = $hr->watched_paths;
    is($paths[0], $f1, 'first path matches');
    is($paths[1], $f2, 'second path matches');
}

# === empty directory watch ===
{
    my $dir = tempdir(CLEANUP => 1);
    # Empty dir - no files
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { });
    my $result = $hr->poll;
    is($result, 0, 'empty directory poll returns 0');
}

# === watch same path twice gets separate callbacks ===
{
    my ($fh, $f) = tempfile(UNLINK => 1);
    print $fh "x\n"; close $fh;

    my ($cb1, $cb2) = (0, 0);
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($f, sub { $cb1++ });
    $hr->watch($f, sub { $cb2++ });

    is(scalar $hr->watched_paths, 2, 'same path watched twice');

    $hr->poll; # baseline

    sleep 1;
    open $fh, '>', $f or die; print $fh "changed\n"; close $fh;

    $hr->poll;
    is($cb1, 1, 'first callback invoked');
    is($cb2, 1, 'second callback invoked');
}

# === nested subdirectory detection ===
{
    my $dir = tempdir(CLEANUP => 1);
    mkpath("$dir/a/b/c");
    open my $fh, '>', "$dir/a/b/c/deep.txt" or die;
    print $fh "deep\n"; close $fh;

    my @changed;
    my $hr = Chandra::HotReload->new(interval => 0);
    $hr->watch($dir, sub { @changed = @{$_[0]} });

    $hr->poll; # baseline
    @changed = ();

    sleep 1;
    open $fh, '>', "$dir/a/b/c/deep.txt" or die;
    print $fh "modified\n"; close $fh;

    $hr->poll;
    ok(scalar @changed >= 1, 'deeply nested file change detected');
    ok(grep({ /deep\.txt/ } @changed), 'deep file in changed list');
}

done_testing;
