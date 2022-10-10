#
# This file is part of Alien-Bazel
#
# This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
package Alien::Bazel::Util;
# ABSTRACT: Private utilities for Alien

use File::Which qw(which);
use Path::Tiny qw(path);
use List::Util qw(first);
use Data::Dumper qw(Dumper);
use Capture::Tiny qw(capture_stdout);
use Config;

sub _is_valid_jdk {
    my ($java_home) = @_;
    return !!0 unless $java_home;
    my @javac_comp = ('bin', "javac$Config{_exe}");
    return -x path($java_home)->child(@javac_comp)
}

sub _find_jdk_java_home {
    my ($class) = @_;
    my @checks;

    if( exists $ENV{JAVA_HOME} && $ENV{JAVA_HOME} ) {
        push @checks, { home => $ENV{JAVA_HOME},
            src => 'JAVA_HOME environment variable' };
    }

    if( my $javac = which('javac') ) {
        my ($version, $exit) = capture_stdout { system($javac, qw(--version)) };
        if( !$exit && $version =~ /javac/s ) {
            my $java_home = path($javac)->realpath->parent(2);
            push @checks, { home => $java_home,
                src => 'javac in PATH' };
        }
    }

    if( $^O eq 'darwin' ) {
        chomp(my $java_home = `/usr/libexec/java_home -v 1.8`);
        push @checks, { home => $java_home,
            src => 'macOS /usr/libexec/java_home' };
    }

    if(my $valid_home = first { _is_valid_jdk($_->{home}) } @checks) {
        return $valid_home->{home};
    } else {
        die <<EOF;
JAVA_HOME detection failed:

Must set JAVA_HOME environment variable.

Attempted to find JAVA_HOME in:

@{[ Dumper(\@checks) ]}

EOF
    }
}

1;
