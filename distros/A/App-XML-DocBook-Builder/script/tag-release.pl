#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    ( map { m{\Aversion * = *(\S+)} ? ($1) : () }
        io->file("./dist.ini")->getlines() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my @cmd = (
    "hg", "tag", "-m",
    "Tagging the App-XML-DocBook-Docmake release as $version",
    "cpan-releases/$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
