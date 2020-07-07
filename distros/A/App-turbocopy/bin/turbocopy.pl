#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;
use App::turbocopy;

# PODNAME: turbocopy.pl
# ABSTRACT: CLI utility to copying files in more effective way using async IO

=head1 NAME

App::turbocopy - CLI utility to copying files in more effective way

=head1 SYNOPSIS

  # copy file a to  new file b
  turbocopy a b

  # copy files recursively from dir a to dir b
  turbocopy -r a/ b/

=head1 DESCRIPTION

This script provides a command to copy files in more effective way using asynchronous IO.

=head1 Options

=over 4

=item -r

copy files recursively

=back

=head1 HINTS

If the target already exists, it will be overwritten without any warning!

If the source is a file and the target is a directory, the source will be copied into target.

If the programm dies with "Too many open files", increase the count of file descriptors (ulimit -n)

=cut

my $is_recursive;
GetOptions(
    'r' => \$is_recursive
) or pod2usage(2);



my $src = shift @ARGV;
my $target = shift @ARGV;

App::turbocopy::run($is_recursive, $src, $target);

1;
