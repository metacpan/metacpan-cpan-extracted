#!/usr/bin/env perl
# File-backed persistence: data survives process restart
#
# Write → exit → reopen → data is still there.
# This is the core value of file-backed mmap vs anonymous.
use strict;
use warnings;
use POSIX qw(_exit);
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::Str;

my $ipath = tmpnam();
my $spath = tmpnam();
END { unlink $ipath, $spath if defined $ipath }

# === Phase 1: create and populate ===
{
    my $ibuf = Data::Buffer::Shared::I64->new($ipath, 100);
    my $sbuf = Data::Buffer::Shared::Str->new($spath, 10, 32);

    $ibuf->fill(0);
    for my $i (0..99) { $ibuf->set($i, $i * $i) }

    $sbuf->set(0, "hello");
    $sbuf->set(1, "world");
    $sbuf->set(2, "persistent");

    printf "phase 1: wrote 100 ints and 3 strings\n";
    printf "  ibuf[50] = %d\n", $ibuf->get(50);
    printf "  sbuf[2]  = '%s'\n", $sbuf->get(2);
    # objects go out of scope here — mmap unmapped
}

# === Phase 2: reopen from files (simulates process restart) ===
{
    my $ibuf = Data::Buffer::Shared::I64->new($ipath, 100);
    my $sbuf = Data::Buffer::Shared::Str->new($spath, 10, 32);

    printf "\nphase 2: reopened from files\n";
    printf "  ibuf[0]  = %d (expected 0)\n", $ibuf->get(0);
    printf "  ibuf[50] = %d (expected 2500)\n", $ibuf->get(50);
    printf "  ibuf[99] = %d (expected 9801)\n", $ibuf->get(99);
    printf "  sbuf[0]  = '%s' (expected 'hello')\n", $sbuf->get(0);
    printf "  sbuf[1]  = '%s' (expected 'world')\n", $sbuf->get(1);
    printf "  sbuf[2]  = '%s' (expected 'persistent')\n", $sbuf->get(2);

    # modify and close
    $ibuf->set(0, 999);
    $sbuf->set(0, "modified");
}

# === Phase 3: verify modifications persisted ===
{
    my $ibuf = Data::Buffer::Shared::I64->new($ipath, 100);
    my $sbuf = Data::Buffer::Shared::Str->new($spath, 10, 32);

    printf "\nphase 3: verify modifications\n";
    printf "  ibuf[0]  = %d (expected 999)\n", $ibuf->get(0);
    printf "  sbuf[0]  = '%s' (expected 'modified')\n", $sbuf->get(0);

    # clear and verify
    $ibuf->clear;
    printf "  ibuf[50] after clear = %d (expected 0)\n", $ibuf->get(50);
}
