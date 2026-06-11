#!/usr/bin/perl

# This script attempts to reproduce:
# https://github.com/shlomif/perl-Config-IniFiles/issues/14

# " Could you please document whether Unicode is supported in the config
# values? "

# Written by Shlomi Fish.
# This file is licensed under the MIT/Expat License.

use strict;
use warnings;
use autodie;
use utf8;

use Test::More tests => 12;

use lib "./t/lib";
use Config::IniFiles;
use File::Spec;
use Config::IniFiles::Slurp qw( slurp utf8_slurp utf8_spew );

use File::Temp qw(tempdir);

{
    my $dir_name = tempdir( CLEANUP => 1 );
    my $filename = File::Spec->catfile( $dir_name, "utf8-test.ini" );
    {
        utf8_spew( $filename, <<'EOF' );
[section]

mykey = tén

EOF
    }

    {
        open my $in, '<:encoding(utf8)', $filename
            or die "Cannot open '$filename' for slurping - $!";

        my $ini = Config::IniFiles->new( -file => $in, );
        close($in);

        # TEST
        ok( ($ini), "Ini was initialised" );

        # TEST
        is( scalar(@Config::IniFiles::errors), 0, "There are no errors." );

        # TEST
        ok( $ini->SectionExists('section'), "section exists" );

        # TEST
        ok( $ini->exists( 'section', 'mykey' ), "section catches parameter" );

        # TEST
        is( $ini->val( 'section', 'mykey' ), qq#tén#, "->val() parameter" );

        $ini->setval( 'section', 'mykey', 'meö שלום' );

        # TEST
        is(
            $ini->val( 'section', 'mykey' ),
            'meö שלום',
            "setval(  ) ; ->val() parameter"
        );

        # TEST
        ok( scalar( $ini->WriteConfig( $filename, ) ), "WriteConfig" );
    }

    {
        open my $in, '<:encoding(utf8)', $filename
            or die "Cannot open '$filename' for slurping - $!";

        my $ini = Config::IniFiles->new( -file => $in, );
        close($in);

        # TEST
        ok( ($ini), "Ini was initialised" );

        # TEST
        is( scalar(@Config::IniFiles::errors), 0, "There are no errors." );

        # TEST
        ok( $ini->SectionExists('section'), "section exists" );

        # TEST
        ok( $ini->exists( 'section', 'mykey' ), "section catches parameter" );

        # TEST
        is(
            $ini->val( 'section', 'mykey' ),
            'meö שלום',
            "->val() parameter"
        );
    }
}
