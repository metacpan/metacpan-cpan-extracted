#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;

my $path_splitter = $ENV{PATH} =~ /;/ ? qr/[;]/ : qr/[:]/;
my @paths = split /$path_splitter/, $ENV[PATH];

# do we have a make command?
my $make  = executable('make');
my $cpanm = executable('cpanm');
my $wget  = executable('wget');
my $curl  = executable('curl');
my $sudo  = executable('sudo') || '';

if ($make) {
    # should be able to install this module
    exec $cpanm ? "$sudo $cpanm ."
        : $wget ? "$wget -O- http://cpanmin.us | $sudo perl - ."
        : $curl ? "$curl -L http://cpanmin.us | $sudo perl - ."
        :         "perl Makefile.PL; make; make install";
}
else {
    # no make assume the user can't install Perl modules (eg in git-bash environment)
    my ($local) = grep {$_ eq "$ENV{HOME}/bin"} @path;

    if ($local) {
        # have ~/bin
        mkdir $local if !-d $local;

        # git-bash has File::Copy (as does Perl 5.8) module assume it's existence
        require File::Copy;
        File::Copy->import('copy');
        opendir my $dirh, "$Bin/bin";
        my @bin = grep {/^git/} readdir $dirh;

        for my $file (@bin) {
            copy("$Bin/bin/$file", "$local/$file");
        }
    }
}

sub executable {
    my ($program) = @_;

    for my $dir (@paths) {
        next if !-e "$dir/$program";
        return "$dir/$program";
    }

    return;
}
