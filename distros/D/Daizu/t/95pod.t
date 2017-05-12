#!/usr/bin/perl
use warnings;
use strict;

# Validate the POD documentation in all Perl modules (*.pm) under the 'lib'
# directory.  Prints a warning if no documentation was found (because that
# probably means you should write some).

use File::Find;
use Pod::Checker;
use File::Temp qw( tempfile );
use Test::More;

# Each test is for a particular '.pm' file, so we need to find how many
# there are before we plan the tests.
my @pm;
find({ wanted => \&wanted, no_chdir => 1 }, 'lib');

# Programs which should also have POD.
push @pm, 'bin/daizu', 'cgi/preview.cgi',
          glob('upgrade/*/*.pl');

sub wanted
{
    return unless -f;
    return unless /\.pm$/i;
    push @pm, $_;
}

plan tests => scalar @pm;


foreach (@pm) {
    # Warnings are sent to a temporary file.
    my ($log_file, $log_filename) = tempfile();

    my $s = podchecker($_, $log_file, '-warnings' => 2);
    close $log_file;

    if ($s < 0) {
        TODO: {
            local $TODO = 'no documentation';
            ok(1, $_);
        }
    }
    elsif ($s > 0) {
        open my $log_file, '<', $log_filename
            or die "$0: error rereading log file '$log_filename': $!\n";
        ok(0, $_);
        diag(do { local $/; <$log_file> });
    }
    else {
        ok(1, $_);
    }

    unlink $log_filename;
}

# vi:ts=4 sw=4 expandtab filetype=perl
