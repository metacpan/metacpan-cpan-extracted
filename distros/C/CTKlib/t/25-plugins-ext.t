#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 25-plugins-ext.t 289 2020-08-31 16:09:21Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 23;

use File::Spec;
use CTK;
use CTK::Util qw/fsave randchars preparedir/;

use constant {
        FILEMASK    => 'test%d.tmp',
        FILENAME    => 'test.tmp',
        TESTURL_FTP => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/test?Passive=1&Timeout=10',
        TESTURL_SFTP=> 'sftp://guest@192.168.123.8/home/guest/Public?timeout=10',
    };

my $ctk = new CTK(
        plugins     => [qw/log file archive ftp sftp/],
        #verbose     => 1,
        #debug       => 1,
        #log         => 1,
    );
ok($ctk->logger_init(file => "error.log"), "Logger initialize");

ok($ctk->status, "CTK with plugins is ok");
note($ctk->error) unless $ctk->status;

# Create dirs
my $src = File::Spec->catdir("src", "src");
my $dst = File::Spec->catdir("src", "dst");
ok(preparedir($src), "Prepare $src");
ok(preparedir($dst), "Prepare $dst");

# Create 3 files with 10 lines
$ctk->debug(sprintf("Creating temp files in \"%s\"...", $src));
foreach my $i (1..3) {
    my @pool;
    for (1..10) { push @pool, sprintf("%02d %s", $_, randchars( 80 )) };
    ok(fsave(File::Spec->catfile($src, sprintf(FILEMASK, $i)), join("\n", @pool)), "Save random file N$i");
}

# Copy files from src to dst
{
    my $cnt = $ctk->fcopy(
            dirsrc => $src,
            dirdst => $dst,
            mask  => qr/tmp$/,
            format => "[FILE]",
        );
    is($cnt, 3, "Copy 3 .tmp files from src to dst by mask");
}

# Copy files from src to dst (uniq)
{
    my $cnt = $ctk->fcopy(
            dirsrc => $src,
            dirdst => $dst,
            glob  => "*.tmp",
            format => "[FILE]",
            uniq => 1,
        );
    is($cnt, 0, "Copy 0 .tmp files from src to dst by mask (uniq)");
}

# Move files from src to dst (uniq)
{
    my $cnt = $ctk->fmove(
            dirsrc => $src,
            dirdst => $dst,
            glob   => "*.tmp",
            format => "[FILE]",
            uniq => 1,
        );
    is($cnt, 0, "Move 0 .tmp files from src to dst by mask (uniq)");
}

# Remove files from src
{
    my $cnt = $ctk->fremove(
            dirsrc => $src,
            glob  => "*.tmp",
        );
    is($cnt, 3, "Remove 3 .tmp files from src");
}

# Join files
{
    my $cnt = $ctk->fjoin(
            dirsrc => $dst,
            dirdst => $src,
            glob  => "*.tmp",
            target => "join.txt",
            eol => "\n",
        );
    ok($cnt, "Join tmp files from dst to src");
}

# Remove files from dst
{
    my $cnt = $ctk->fremove(
            dirsrc => $dst,
            glob  => "*.tmp",
        );
    ok($cnt, "Remove .tmp files from dst");
}

# Split file to dst dir
{
    my $cnt = $ctk->fsplit(
            dirsrc => $src,
            file   => "join.txt",
            dirdst => $dst,
            lines  => 3,
        );
    is($cnt, 1, "Split one file to dst");
}

# Remove files from src
{
    my $cnt = $ctk->fremove(
            dirsrc => $src,
        );
    ok($cnt, "Remove files from src");
}

# Compress
{
    my $cnt = $ctk->fcompress(
            dirsrc => $dst,
            archive=> File::Spec->catfile($src, "archive.tar.gz"),
            glob   => "*.part*",
            arcdef => "targz",
        );
    ok($cnt, "Archive all files from dst to src/archive.tar.gz");
}

# Extract
{
    my $cnt = $ctk->fextract(
            dirsrc => $src,
            dirdst => $dst,
            glob   => "*.tar.gz",
            arcdef => "targz",
        );
    ok($cnt, "Extract all .tar.gz files from src to dst");
}

# Remove files from dst
{
    my $cnt = $ctk->fremove(
            dirsrc => $dst,
        );
    ok($cnt, "Remove files from src");
}

# Store files to ftp
{
    my $cnt = $ctk->store_ftp(
        dirsrc  => $src, # Source directory
        url     => TESTURL_FTP,
        op      => "move", # copy / move
        uniq    => 0, # 0 -- off; 1 -- on
        mode    => "binary", # ascii / binary (default)
        glob    => "*.tar.gz",
    );
    ok($cnt, "Store files from src to FTP");
}

# Fetch files from ftp
{
    my $cnt = $ctk->fetch_ftp(
        url     => TESTURL_FTP,
        op      => "copy", # copy / move
        uniq    => 0, # 0 -- off; 1 -- on
        mode    => "binary", # ascii / binary (default)
        dirdst  => $src, # Destination directory
        filter  => qr/\.tar\.gz$/,
    );
    ok($cnt, "Fetch files from FTP");
}

# Store files to sftp
{
    my $cnt = $ctk->store_sftp(
        dirsrc  => $src, # Source directory
        url     => TESTURL_SFTP,
        op      => "move", # copy / move
        uniq    => 0, # 0 -- off; 1 -- on
        mode    => "binary", # ascii / binary (default)
        glob    => "*.tar.gz",
    );
    ok($cnt, "Store files from src to SFTP");
}

# Fetch files from sftp
{
    my $cnt = $ctk->fetch_sftp(
        url     => TESTURL_SFTP,
        op      => "copy", # copy / move
        uniq    => 0, # 0 -- off; 1 -- on
        mode    => "binary", # ascii / binary (default)
        dirdst  => $src, # Destination directory
        filter  => qr/\.tar\.gz$/,
    );
    ok($cnt, "Fetch files from SFTP");
}

# Remove files from src
{
    my $cnt = $ctk->fremove(
            dirsrc => $src,
        );
    ok($cnt, "Remove files from src");
}

1;

__END__
