#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 21;

use File::Spec;
use CTK;
use CTK::Util qw/fsave randchars preparedir/;

use constant FILENAME => 'test%d.tmp';

my $ctk = CTK->new(
        plugins     => [qw/archive log/],
        #verbose     => 1,
        #debug       => 1,
        #log         => 1,
    );
ok($ctk->logger_init(file => "error.log"), "Logger initialize");

ok($ctk->status, "CTK with plugins is ok");
note($ctk->error) unless $ctk->status;

my $src = "src";
my $dst = File::Spec->catdir("src", "dst");
my $dst2 = File::Spec->catdir("src", "dst2");
ok(preparedir($dst), "Prepare $dst");
ok(preparedir($dst2), "Prepare $dst2");

# Create 3 files with 10 lines
$ctk->debug(sprintf("Creating temp files in \"%s\"...", $src));
foreach my $i (1..3) {
    my @pool;
    for (1..10) { push @pool, sprintf("%02d %s", $_, randchars( 80 )) };
    ok(fsave(File::Spec->catfile($src, sprintf(FILENAME, $i)), join("\n", @pool)), "Save random file N$i");
}

# Archive files to dst
$ctk->debug(sprintf("Archive files to \"%s\"...", $dst));

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.tgz"),
        -glob   => "*.tmp",
        -arcdef => "tgz",
    ), "Archive all .tmp files from src to archive.tgz");

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.tar.gz"),
        -glob   => "*.tmp",
        -arcdef => "targz",
    ), "Archive all .tmp files from src to archive.tar.gz");

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.gz"),
        -file   => "test1.tmp",
        -arcdef => "gz",
    ), "Archive test1.tmp file from src to archive.gz");

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.zip"),
        -glob   => "*.tmp",
        -arcdef => "zip",
    ), "Archive all .tmp files from src to archive.zip");

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.tar.bz2"),
        -glob   => "*.tmp",
        -arcdef => "tarbz2",
    ), "Archive all .tmp files from src to archive.tar.bz2");

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.tar.xz"),
        -glob   => "*.tmp",
        -arcdef => "tarxz",
    ), "Archive all .tmp files from src to archive.tar.xz");

ok($ctk->fcompress(
        -dirsrc => $src,
        -archive=> File::Spec->catfile($dst, "archive.tar"),
        -glob   => "*.tmp",
        -arcdef => "tar",
    ), "Archive all .tmp files from src to archive.tar");


#
# Extract
#

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.tar.gz",
        -arcdef => "targz",
    ), "Extract all .tar.gz files from dst to dst2");

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.tgz",
        -arcdef => "tgz",
    ), "Extract all .tgz files from dst to dst2");

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.gz",
        -arcdef => "gz",
    ), "Extract all .gz files from dst to dst2");

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.zip",
        -arcdef => "zip",
    ), "Extract all .zip files from dst to dst2");

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.tar.bz2",
        -arcdef => "tarbz2",
    ), "Extract all .tar.bz2 files from dst to dst2");

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.tar.xz",
        -arcdef => "tarxz",
    ), "Extract all .tar.xz files from dst to dst2");

ok($ctk->fextract(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -glob   => "*.tar",
        -arcdef => "tar",
    ), "Extract all .tar files from dst to dst2");

1;

__END__

