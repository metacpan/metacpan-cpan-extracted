#!/usr/bin/perl

# This script attempts to reproduce:
# https://rt.cpan.org/Ticket/Display.html?id=36584

# Written by Shlomi Fish.
# This file is licensed under the MIT/Expat License.

use strict;
use warnings;

use Test::More tests => 7;

use lib "./t/lib";
use Config::IniFiles;
use File::Spec;
use Config::IniFiles::Slurp qw( slurp );

use File::Temp qw(tempdir);

{
    my $dir_name = tempdir( CLEANUP => 1 );
    my $filename = File::Spec->catfile( $dir_name, "foo.ini" );
    {
        open my $fh, '>', $filename;
        print {$fh} <<'EOF';

; This is a malformed ini file with a key/value outside a section

wrong = wronger

[section]

right = more right

EOF
        close($fh);
    }

    my $ini = Config::IniFiles->new( -file => $filename );

    # TEST
    ok( !defined($ini), "Ini was not initialised" );

    # TEST
    is( scalar(@Config::IniFiles::errors), 1, "There is one error." );

    # TEST
    like(
        $Config::IniFiles::errors[0],
        qr/parameter found outside a section/,
        "Error was correct - 'parameter found outside a section'",
    );

    $ini = Config::IniFiles->new( -file => $filename, -fallback => 'GENERAL' );

    # TEST
    ok( defined($ini), "(-fallback) Ini was initialised" );

    # TEST
    ok( $ini->SectionExists('GENERAL'), "(-fallback) Fallback section exists" );

    # TEST
    ok( $ini->exists( 'GENERAL', 'wrong' ),
        "(-fallback) Fallback section catches parameter" );

    # TEST
    my $newfilename = File::Spec->catfile( $dir_name, "new.ini" );
    $ini->WriteConfig($newfilename);
    my $content = slurp($newfilename);
    ok(
        $content =~ /^wrong/m && $content !~ /^\[GENERAL\]/m,
        "(-fallback) Outputting fallback section without section header"
    );
}
