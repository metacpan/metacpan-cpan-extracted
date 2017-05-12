#!/usr/bin/perl

# This is a Quick and dirty script to generate docs.
#
# It can do three things:
#    1) make HTML docs that look like those on search.cpan.org
#    2) make text docs
#    3) copy files
#
# Run this from the main module directory with:
#     $ misc/makedocs.pl
#

my $StyleSheet = "misc/style.css";

my %HTML = (
    'CGI-Application-Framework.html' => 'lib/CGI/Application/Framework.pm',
    'Examples.html'                  => 'Examples.pod',
);

my %TEXT = (
);

my %COPY = (
    'changes.txt'  => 'Changes',
    'readme.txt'   => 'README',
);

my @Tempfiles = qw(
    pod2htmd.tmp
    pod2htmd.x~~
    pod2htmi.tmp
    pod2htmi.x~~
);

use strict;
use File::Copy;
local $/;

foreach my $target (keys %TEXT) {
    my $source = $TEXT{$target};
    system("pod2text $source $target");
}

foreach my $target (keys %HTML) {
    my $source = $HTML{$target};

    system("pod2html --css=$StyleSheet $source $target");

    open my $fh, $target or die "can't read $target: $!\n";
    my $text = <$fh>;
    close $fh;


    # Add <div class="pod">...</div>
    $text =~ s/(<body[^>]*>)/$1<div class="pod">/i;
    $text =~ s/(<\/body>)/<\/div>$1/i;


    # remove redundant </pre>  <pre> sequences (only necessary in old pod2html)
    # $text =~ s/<\/pre>(\s*)<pre>/$1/imsg;

    # remove redundant </pre> </dd> <dd> <pre> tags (only necessary in old pod2html)
    # $text =~ s/<\/pre>(\s*)<\/dd>\s*<dd>\s*<pre>/$1/imsg;


    open my $fh, '>', $target or die "can't clobber $target: $!\n";
    print $fh $text;
    close $fh;

    foreach my $tempfile (@Tempfiles) {
        unlink $tempfile;
    }
}

foreach my $target (keys %COPY) {
    my $source = $COPY{$target};
    copy($source, $target);
}


