#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);

use Cwd;
use IO::Dir;
use IO::File;
use MIME::Base64  qw(encode_base64);
use File::Spec::Functions qw(catfile no_upwards rel2abs splitdir);

#----------------------------------------------------------------------
# Configuration

# Prefix that preceds every command in data section
# Must agree with Initialize.pm
use constant CMD_PREFIX => '#>>>';

# The name of the index file in the template
my $index_file = 'index.html';

# The location of the initialization module relative to this file
my $output = 'lib/App/Followme/Initialize.pm';

#----------------------------------------------------------------------
# Main routine

my $dir = shift(@ARGV) or die "Must supply site directory\n";
$dir  = rel2abs($dir);

chdir ($Bin);
my $out = copy_script($output);

chdir($dir);

my $visitor = get_visitor();
while (my $file = &$visitor) {
    bundle_file($out, $file);
}

close($out);

chdir($Bin);
rename("$output.TMP", $output);

#----------------------------------------------------------------------
# Append a binary file to the bundle

sub append_binary_file {
    my ($out, $file) = @_;


    my $in = IO::File->new($file, 'r');
    die "Couldn't read $file: $!\n" unless $in;

    binmode $in;
    my $buf;

    while (read($in, $buf, 60*57)) {
        print $out encode_base64($buf);
    }

    close($in);
    return;
}

#----------------------------------------------------------------------
# Append a text file to the bundle

sub append_text_file {
    my ($out, $file) = @_;

    my $in = IO::File->new($file, 'r');
    die "Couldn't read $file: $!\n" unless $in;

    while (defined (my $line = <$in>)) {
        chomp($line);
        print $out $line, "\n";
    }

    close($in);
    return;
}

#----------------------------------------------------------------------
# Append a file to the bundle

sub bundle_file {
    my ($out, $file) = @_;

    my ($type, $cmd);
    if ($file =~ /\.cfg$/) {
        $type = 'configuration';
        my ($new_file, $version) = get_version($file);
        $cmd = join(' ', CMD_PREFIX, 'copy', $type, $new_file, $version);

    } else {
        $type = -B $file ? 'binary' : 'text';
        $cmd = join(' ', CMD_PREFIX, 'copy', $type, $file);
    }

    print $out $cmd, "\n";
    if ($type eq 'binary') {
        append_binary_file($out, $file);
    } else {
        append_text_file($out, $file);
    }

    return;
}

#----------------------------------------------------------------------
# Copy the script to start

sub copy_script {
    my ($output) = @_;

    my @path = split(/\//, $output);
    $output = catfile(@path);

    my $last = "__DATA__\n";
    my $in = IO::File->new($output, 'r') or
        die "Couldn't read $output: $!\n";

    $output .= '.TMP';
    my $out = IO::File->new($output, 'w');
    die "Couldn't write to script: $output\n" unless $out;

    while (<$in>) {
        print $out $_;
        last if $_ eq $last;
    }

    close($in);
    return $out;
}

#----------------------------------------------------------------------
# Set the maximum version of any file

sub get_version {
    my ($file) = @_;

    my $version;
    if ($file =~ /_vsn\d+\./) {
        my $ext;
        my ($base, $rest) = split(/_vsn/, $file, 2);
        ($version, $ext) = split(/\./, $rest, 2);
        $file = "$base.$ext";

    } else {
        $version = 0;
    }

    return ($file, $version);
}

#----------------------------------------------------------------------
# Return a closure that visits files in a directory

sub get_visitor {
    my () = @_;

    my @dirlist;
    my @filelist;
    push(@dirlist, '.');

    return sub {
        for (;;) {
            my $file = shift @filelist;
            return $file if defined $file;

            my $dir = shift @dirlist;
            return unless defined $dir;

            my $dd = IO::Dir->new($dir) or die "Couldn't open $dir: $!\n";

            while (defined ($file = $dd->read())) {
                next if $file =~ /^\./;
                my $path = $dir ne '.' ? catfile($dir, $file) : $file;

                if (-d $path) {
                    push(@dirlist, $path) if no_upwards($file);

                } else {
                    push(@filelist, $path);
                }
            }

            @filelist = sort(@filelist);
            @dirlist = sort(@dirlist);
            $dd->close;
        }
    };
}

#----------------------------------------------------------------------
# Split topmost directory off from file name

sub split_dir {
    my ($file) = @_;

    my@path = splitdir($file);
    my $dir = shift(@path);
    my $rest = catfile(@path);

    return ($dir, $rest);
}

__END__

=encoding utf-8

=head1 NAME

bundle.pl - Combine website files with Initialize module

=head1 SYNOPSIS

    perl bundle.pl directory

=head1 DESCRIPTION

When followme is called with the -i flag it creates a new website in a directory,
including the files it needs to run. These files are extraced from the DATA
section at the end of the Initialize.pm module. This script updates that DATA section
from a directory containing a sample website. It is for developers of this code
and not for end users.

Run this script with the name of the directory containing the sample website on
the command line.

=head1 CONFIGURATION

The following variabless are defined in the configuration section at the top of
the script:

=over 4

=item CMD_PREFIX

The string which marks a line in the DATA section as a command. It must match
the constant of the same name in the Initialize.pm module.

=item $output

The file path to the Initialize.pm module relative to the location of this script.
Directories should be separated by forward slashes (/) regardless of the convention
of the operating system.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut
