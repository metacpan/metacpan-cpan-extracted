#!/usr/bin/perl
# This script is a regression test for:
#
# https://rt.cpan.org/Ticket/Display.html?id=45997
#
# Failure to read the ini file contents from a filehandle made out of a scalar

use Test::More tests => 1;

use strict;
use warnings;

use IO::File;

use lib "./t/lib";
use Config::IniFiles::Slurp qw( slurp );

use Config::IniFiles;
use File::Spec;

use File::Temp qw(tempdir);

my $dirname  = tempdir( CLEANUP => 1 );
my $filename = File::Spec->catfile( $dirname, 'toto.ini' );

{
    {
        open my $fh, '>', $filename;
        print {$fh} <<'EOF';
[toto]
tata=verylongstringtoreplacewithashorterone

[section3]
arg3=valf
EOF
        close($fh);
    }
    {
        my %ini;

        my $fh = IO::File->new( $filename, 'r+' );
        die "Couldn't open file ${filename}: $!" if not defined $fh;
        tie %ini, 'Config::IniFiles', ( -file => $fh, -allowempty => 1 );

        tied(%ini)->delval( "toto", "tata" );
        tied(%ini)->RewriteConfig;

        $ini{toto}{tata} = 'short';
        tied(%ini)->RewriteConfig;

        $fh->close;
        untie %ini;
    }

    # TEST
    is(
        scalar( slurp($filename) ),
        <<'EOF',
[toto]
tata=short

[section3]
arg3=valf
EOF
        "Test that the value was properly shortened.",
    );
}
