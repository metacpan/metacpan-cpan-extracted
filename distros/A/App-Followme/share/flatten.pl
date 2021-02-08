#!/usr/bin/perl

use strict;
use warnings;

use Cwd;
use IO::Dir;
use IO::File;
use Getopt::Std;
use File::Spec::Functions qw(catfile  no_upwards rel2abs splitdir);

#----------------------------------------------------------------------
# Main

my %opt;
getopts('r', \%opt);
my $folder = shift(@ARGV) or getcwd();
die ("$folder is not a directory") unless -e $folder && -d $folder;

if ($opt{r}) {
    revert_files($folder);
} else {
    alter_files($folder);
}

#----------------------------------------------------------------------
# Alter the files in a folder

sub alter_files {
    my ($folder) = @_;
    my @files = find_files($folder);

    foreach my $file (@files) {
        my $text = slurp_file($file);
        backup_file($file, $text);

        $text = alter_text($text);
        write_file($file, $text);
    }

    return;
}

#----------------------------------------------------------------------
# Alter the file names in a file

sub alter_text {
    my ($text) = @_;

    $text =~ s/src="([^"]*)"/'src="' . alter_url($1) . '"'/ge;
    $text =~ s/href="([^"]*)"/'href="' . alter_url($1) . '"'/ge;
    $text =~ s/url\('([^']*)'\)/'url(\'' . alter_url($1) . '\')'/ge;

    return $text;
}

#----------------------------------------------------------------------
# Modify a url to point at the file's new location

sub alter_url {
    my ($url) = @_;

    if ($url !~ /:/) {
        my @path = split(/\//, $url);
        $url = pop(@path);
    }

    return $url;
}

#----------------------------------------------------------------------
# Create a backup copy of the original file

sub backup_file {
    my ($file, $text) = @_;
    $file .= '~';

    write_file($file, $text);
}

#----------------------------------------------------------------------
# Find files to modify

sub find_files {
    my ($folder) = @_;

    my @files;
    my $dd = IO::Dir->new($folder);
    while (defined (my $file = $dd->read())) {
        next unless no_upwards($file);
        my $file = catfile($folder, $file);

        if (-d $file) {
            push(@files, find_files($file));
        } else {
            push(@files, $file) if text_file($file);
        }
    }

    return @files;
}

#----------------------------------------------------------------------
# Alter the files in a folder

sub revert_files {
    my ($folder) = @_;
    my @files = find_files($folder);

    foreach my $file (@files) {
        my $old_file = "$file~";
        rename($old_file, $file) if -e $old_file;
    }

    return;
}

#----------------------------------------------------------------------
# Read the file into a single string

sub slurp_file {
    my ($path) = @_;

    local $/;
    my $fd = IO::File->new($path, 'r');
    die "Couldn't read file ($path): $!\n" unless $fd;

    my $text = <$fd>;
    return $text;
}

#----------------------------------------------------------------------
# Test if a file is a text file

sub text_file {
    my ($file) = @_;

    for my $ext (qw(html css)) {
        return 1 if $file =~ /\.$ext$/;
    }

    return;
}

#----------------------------------------------------------------------
# Read the file into a single string

sub write_file {
    my ($file, $text) = @_;

    my $fd = IO::File->new($file, 'w');
    die "Couldn't write file ($file): $!\n" unless $fd;

    print $fd $text;
    close($fd);
}

=encoding utf-8

=head1 NAME

flatten.pl - Modify web files so they are in a single flat directory

=head1 SYNOPSIS

    perl flatten.pl directory

=head1 DESCRIPTION

This script modifies the contents of a directory containing web files so that the
relative urls they contain point to files in the same directory.It's assumed
that the files have already been copied into a single directory before this
script is run.

=head1 FLAGS

This script supports a single command line flag:

=over 4

=item -r

Before modifying the file the script creates a backup copy whose name is
the same with an appended ~ character. If the -r flag is on the command
line, instead of modifying the files, it restores the original file by
copying the old version over the modified version. This script for
developers of this code and not for end users.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
