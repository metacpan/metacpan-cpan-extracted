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
plan skip_all => "TEST_NET environment variable required" unless $ENV{TEST_NET};
plan tests => 11;

use File::Spec;
use CTK;
use CTK::Util qw/fsave randchars preparedir/;

use constant {
        FILEMASK    => 'test%d.tmp',
        TESTURL_FTP => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/test?Passive=1&Timeout=10&Debug=0',
        TESTURL_SFTP=> 'sftp://guest@192.168.123.8/home/guest/Public?timeout=10',
    };

my $ctk = CTK->new(
        plugins     => [qw/log net/],
        verbose     => 1,
        debug       => 1,
        log         => 1,
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

# Store files to ftp
{
    ok($ctk->store(
            -url        => TESTURL_FTP,
            -dirin      => $src,
        ), "Send all files to FTP ". TESTURL_FTP);
}

# Fetch files from ftp
{
    my $cnt = $ctk->fetch_ftp(
        url     => TESTURL_FTP,
        op      => "copy", # copy / move
        uniq    => 0, # 0 -- off; 1 -- on
        mode    => "binary", # ascii / binary (default)
        dirdst  => $dst, # Destination directory
    );
    ok($cnt, "Fetch files from FTP");
}

# Store files to sftp
{
    ok($ctk->store(
            -url        => TESTURL_SFTP,
            -dirin      => $src,
            -op         => "move",
        ), "Send all files to SFTP ". TESTURL_SFTP);
}

# Fetch files from sftp
{
    my $cnt = $ctk->fetch_sftp(
        url     => TESTURL_SFTP,
        op      => "move", # copy / move
        uniq    => 0, # 0 -- off; 1 -- on
        mode    => "binary", # ascii / binary (default)
        dirdst  => $dst, # Destination directory
    );
    ok($cnt, "Fetch files from SFTP");
}

1;

__END__
