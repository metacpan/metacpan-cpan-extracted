#!/usr/bin/perl

use strict;
use warnings;

use IO::All qw/ io /;

my ($version) =
    ( map { m{\Aversion * = *(\S+)} ? ($1) : () }
        io->file("./dist.ini")->getlines() );

if ( !defined($version) )
{
    die "Version is undefined!";
}

my @cmd = (
    "git", "tag", "-m", "Tagging the prefixintsumcol release as $version",
    "prefixintsumcol-$version",
);

print join( " ", map { /\s/ ? qq{"$_"} : $_ } @cmd ), "\n";
exec(@cmd);
