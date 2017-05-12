#!/usr/bin/perl

# This script attempts to reproduce:
# https://sourceforge.net/tracker/index.php?func=detail&aid=1230339&group_id=6926&atid=106926

use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;

use Config::IniFiles;

my $filename = File::Spec->catfile(
    File::Spec->curdir(), "t", "store-and-retrieve-here-doc-terminator.ini"
);

my @file_write_subs =
(
    sub {
        my ($cfg) = @_;

        $cfg->WriteConfig($filename);

        return;
    },
    sub {
        my ($cfg) = @_;

        open my $fh, '>', $filename
            or die "Cannot open '$filename' for writing - $!";
        $cfg->OutputConfigToFileHandle($fh);
        close($fh);

        return;
    },
);
foreach my $write_sub (@file_write_subs)
{
    # Prepare the offending file.
    {
        # Delete the stray file - we want to over-write it.
        unlink($filename);
        my $cfg=Config::IniFiles->new();

        $cfg->newval ("MySection", "MyParam", "Hello\nEOT\n");

        $write_sub->($cfg);
    }

    {
        my $cfg=Config::IniFiles->new(-file => $filename);

        # TEST*2
        is (scalar($cfg->val ("MySection", "MyParam")),
            "Hello\nEOT\n",
            "Default here-doc terminator was stored and retrieved correctly",
        );
    }

# Delete it again to keep the working-copy clean.
    unlink($filename);
}
