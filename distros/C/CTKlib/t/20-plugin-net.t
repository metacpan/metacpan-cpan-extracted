#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 20-plugin-net.t 241 2019-05-07 16:23:14Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 9;

use File::Spec;
use CTK;
use CTK::Util qw/fsave randchars preparedir/;

use constant {
        FILENAME => 'test%d.tmp',
        TESTURL  => 'ftp://anonymous:anonymous@192.168.200.8/mbutiny/rsp.mns?Debug=1&Passive=1',
    };

my $ctk = new CTK(
        plugins     => [qw/net log/],
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

# Store files to url
$ctk->debug(sprintf("Send files to \"%s\"...", TESTURL));
ok($ctk->store(
        -url     => TESTURL,
        -command => "copy",
        -dirin  => $src,
        -regexp   => qr/tmp$/,
    ), "Send .tmp files to URL");


# Fetch files from url
$ctk->debug(sprintf("Fetch files from \"%s\"...", TESTURL));
ok($ctk->fetch(
        -url     => TESTURL,
        -command => "move",
        -dirout  => $dst,
        -regexp   => qr/tmp$/,
    ), "Fetch .gz files from URL");

1;

__END__

