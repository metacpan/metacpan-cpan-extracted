#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) =
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () }
    io->file("./lib/App/XML/DocBook/Docmake.pm")->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my $mini_repos_url = "https://svn.berlios.de/svnroot/repos/web-cpan/App-XML-DocBook-Docmake/";

my @cmd = (
    "hg", "tag", "-m",
    "Tagging the App-XML-DocBook-Docmake release as $version",
    "cpan-releases/$version",
);

print join(" ", map { /\s/ ? qq{"$_"} : $_ } @cmd), "\n";
exec(@cmd);
