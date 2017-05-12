#!/usr/bin/perl
use warnings;
use strict;

# Check that the 'MANIFEST' and 'MANIFEST.SKIP' files are valid, and that
# they match the files which really exist, printing warnings if any files
# appear to be missing from the manifest.

use File::Find qw( find );

# Read MANIFEST
my %manifest;
{
    open my $fh, '<', 'MANIFEST'
        or die "$0: error opening 'MANIFEST': $!\n";
    while (<$fh>) {
        next unless /\S/;
        chomp or warn "MANIFEST:$.: missing newline\n";
        s/\s.*//;
        next if $_ eq 'SIGNATURE';  # doesn't exist until the dist is made

        if (-d $_) {
            warn "MANIFEST:$.: file '$_' is a directory\n";
        }
        elsif (!-f $_) {
            warn "MANIFEST:$.: file '$_' is missing\n";
        }
        else {
            warn "MANIFEST:$.: file '$_' listed a second time\n"
                if exists $manifest{$_};
            $manifest{$_} = 1;
        }
    }
}

# Read MANIFEST.SKIP
my @skip;
{
    open my $fh, '<', 'MANIFEST.SKIP'
        or die "$0: error opening 'MANIFEST.SKIP': $!\n";
    while (<$fh>) {
        next unless /\S/;
        next if /^\s*#/;
        chomp or warn "MANIFEST.SKIP:$.: missing newline\n";
        push @skip, qr/$_/;
    }
}

# Check the files which exist, looking for ones which aren't listed.
my @missing;
find({ wanted => \&_wanted, no_chdir => 1 }, '.');

if (@missing) {
    print STDERR "Files missing from MANIFEST:\n";
    for (@missing) {
        print STDERR "$_\n";
    }
}


sub _wanted
{
    s/^\.\///;
    return if -d;

    my $file = $_;
    for (@skip) {
        return if $file =~ /$_/;
    }

    push @missing, $file
        unless $manifest{$file};
}

# vi:ts=4 sw=4 expandtab
