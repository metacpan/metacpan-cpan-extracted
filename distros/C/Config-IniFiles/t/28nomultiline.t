#!/usr/bin/perl

use Test::More tests => 2;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec;
use File::Temp qw(tempdir);
use lib "./t/lib";
use Config::IniFiles::Slurp qw( slurp );

{
    my $dir_name = tempdir( CLEANUP => 1 );
    my $filename = File::Spec->catfile( $dir_name, "foo.ini" );
    {
        open my $out, '>', $filename;
        print {$out} <<'EOF';
[section]
a = 1
a = 2

EOF
        close($out);
    }

    my $ini = Config::IniFiles->new( -file => $filename, -nomultiline => 1 );

    # TEST
    ok( defined($ini), "Ini was initialised" );

    $ini->RewriteConfig;
    my $content = slurp($filename);
    ok( $content !~ /EOT/ && $content =~ /^a=1/m && $content =~ /^a=2/m,
        "No multiline is output" );
}
