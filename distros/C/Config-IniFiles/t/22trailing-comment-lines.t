#!/usr/bin/perl

# This script attempts to reproduce:
# https://rt.cpan.org/Ticket/Display.html?id=30402
#
# #30402: WriteConfig does not write the last lines of a file if they are comments

use Test::More tests => 1;

use strict;
use warnings;

use File::Spec;

use Config::IniFiles;

{
    my $conf = Config::IniFiles->new(
        -file => File::Spec->catfile(File::Spec->curdir(), 't', 'trailing-comments.ini')
    );

    my $new_file = File::Spec->catfile(
        File::Spec->curdir(), 't', 'new-trail.ini'
    );

    $conf->WriteConfig($new_file);

    my $buffer;
    {
        local $/;
        open my $fh, "<", $new_file;
        $buffer = <$fh>;
        close($fh);
    }

    # TEST
    like(
        $buffer,
        qr{; End Comment 1\n; End Comment 2\n+\z}ms,
        "WriteConfig() Preserved end comments."
    );

    # Remove the generated files so they won't pollute the filesystem /
    # working-copy.
    unlink($new_file);
}

