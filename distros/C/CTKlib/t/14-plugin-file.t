#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 14-plugin-file.t 237 2019-05-06 14:22:39Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 17;

use File::Spec;
use CTK;
use CTK::Util qw/preparedir fsave randchars/;

use constant FILENAME => 'test.tmp';

my $ctk = new CTK(
        plugins     => [qw/file log/],
        ident       => "Test",
        #verbose     => 1,
        #debug       => 1,
        #log         => 1,
    );
ok($ctk->logger_init(file => "error.log"), "Logger initialize");

ok($ctk->status, "CTK with plugins is ok");
note($ctk->error) unless $ctk->status;
my $dst = File::Spec->catdir("src", "dst");
my $dst2 = File::Spec->catdir("src", "dst2");
ok(preparedir($dst), "Prepare $dst");
ok(preparedir($dst2), "Prepare $dst2");

$ctk->debug(sprintf("Copy files to \"%s\"...", $dst));
ok($ctk->fcopy(
        -dirsrc => "src",
        -dirdst => $dst,
        -mask  => qr/pl$/,
        -format => "[FILE].[COUNT]",
    ), "Copy all .pl files from src to dst by mask");

ok($ctk->fcopy(
        -dirsrc => "src",
        -dirdst => $dst,
        -glob   => "*.conf",
        -format => undef,
    ), "Copy all .conf files from src to dst by glob");

ok($ctk->fcopy(
        -dirsrc => "src",
        -dirdst => $dst,
        -files  => ["*.sample", "*.txt"],
        -format => undef,
    ), "Copy all .sample and .txt files from src to dst by glob");

ok($ctk->fcopy(
        -dirsrc => "src",
        -dirdst => $dst,
        -glob   => "*.gz",
        -callback => sub {
            my $name = shift;
            my $count = shift;
            return sprintf("%s_%d_%s", $$, $count, $name) if $name =~ /quux/;
            return;
        },
    ), "Copy all .gz files from src to dst formatted with callback");


# Move
$ctk->debug(sprintf("Move files to \"%s\"...", $dst2));
ok($ctk->fmove(
        -dirsrc => $dst,
        -dirdst => $dst2,
    ), "Move all files from dst to dst2");

# Remove
$ctk->debug(sprintf("Remove files from \"%s\"...", $dst2));
ok($ctk->fremove(
        -dirsrc => $dst2,
        -glob   => "*.gz",
    ), "Removing .gz files from dst2");
ok($ctk->fremove(
        -dirsrc => $dst2,
    ), "Removing all files from dst2");

# Create file with 10 lines
my @pool;
for (1..10) { push @pool, sprintf("%02d %s", $_, randchars( 80 )) };
ok(fsave(FILENAME, join("\n", @pool)), "Save random file");

# Split file to dst dir
ok($ctk->fsplit(
        -file   => FILENAME,
        -dirdst => $dst,
        -lines  => 3,
    ), "Split file to dst");

# Split file to dst dir
ok($ctk->fjoin(
        -dirsrc => $dst,
        -dirdst => $dst2,
        -outfile => "join.txt",
    ), "Joining files from dst to dst2");

# Remove
$ctk->debug(sprintf("Removing all files from \"%s\"...", $dst));
ok($ctk->fremove(
        -dirsrc => $dst,
    ), "Removing all files from dst");
$ctk->debug(sprintf("Removing all files from \"%s\"...", $dst2));
ok($ctk->fremove(
        -dirsrc => $dst2,
    ), "Removing all files from dst2");

ok(unlink(FILENAME), "Delete temp file");

1;

__END__

