#! /usr/bin/env perl

use strict;
use warnings;

use Path::Tiny qw/ path /;

my ($version) =
    ( map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
        path("./lib/Config/IniFiles/")->lines_utf8() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my $DIST = "Config-IniFiles";
my $TAG  = "releases/$version";

my @cmd =
    ( "git", "tag", "-m", "Tagging the $DIST release as $version", "$TAG", );

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
