#!/usr/bin/perl

# This script attempts to reproduce:
# https://github.com/shlomif/perl-Config-IniFiles/issues/6

use strict;
use warnings;

use Test::More tests => 3;
use File::Spec;

use Config::IniFiles;

use lib './t/lib';
use Config::IniFiles::TestPaths;

{
    local $@ = '';
    my $ERRORS = '';
    local $SIG{__WARN__} = sub { $ERRORS .= $_[0] };

    my $ini;
    eval {
        $ini = Config::IniFiles->new(
            -file => t_file('here-doc-no-end-marker.ini') );
    };

    # TEST
    ok( !$@ && !$ERRORS && !defined($ini),
        'A file with no heredoc end marker should fail, but not throw errors' );

    # TEST
    is( scalar(@Config::IniFiles::errors), 1, 'There is one error.' );

    # TEST
    like(
        $Config::IniFiles::errors[0],
        qr/no end marker \("NOEND"\) found/,
        q/Error was correct - 'no end marker ("NOEND") found'/,
    );
}
