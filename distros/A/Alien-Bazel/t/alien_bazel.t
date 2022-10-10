#
# This file is part of Alien-Bazel
#
# This software is Copyright (c) 2022 by Auto-Parallel Technologies, Inc.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Bazel;
use Alien::Bazel::Util;
use Env qw( @PATH $JAVA_HOME );
use Cwd;  # for getcwd()
use Data::Dumper;

our $VERSION = 0.031_000;

plan tests => 47;

alien_diag 'Alien::Bazel';
alien_ok 'Alien::Bazel';

# avoid failures due to missing `bazel` binary; "Failed test 'run bazel version': command not found"
my $bazel_bin_dir = Alien::Bazel->bin_dir;
unshift @PATH, $bazel_bin_dir;
diag '<<< DEBUG >>> have $bazel_bin_dir = ', $bazel_bin_dir, "\n";

my Test::Alien::Run $stage0_version = run_ok([ 'bazel', '--version' ]);
diag '<<< DEBUG >>> have $stage0_version = ', Dumper($stage0_version), "\n";
$stage0_version->success();
$stage0_version->out_like(qr{bazel ([0-9\.]+)});

my Test::Alien::Run $stage0_error = run_ok([ 'bazel', 'FOOBAR' ]);
diag '<<< DEBUG >>> have $stage0_error = ', Dumper($stage0_error), "\n";
$stage0_error->exit_isnt(0);
$stage0_error->err_like(qr{Command 'FOOBAR' not found});

# Bazel C++ Tutorial
# https://bazel.build/start/cpp
# 20220913 "cpp-tutorial" directory retrieved via `git clone`
# https://github.com/bazelbuild/examples/tree/main/cpp-tutorial

# C++, Stages 1 - 3
# $ cd cpp-tutorial/stage1
# $ bazel build //main:hello-world
# INFO: Found 1 target...
# Target //main:hello-world up-to-date:
#   bazel-bin/main/hello-world
# INFO: Elapsed time: 2.267s, Critical Path: 0.25s
# $ bazel-bin/main/hello-world
# Hello world
# Wed Sep 21 21:12:12 2022
# $ cd ../stage2
# REPEAT BUILD
# $ cd  ../stage3
# REPEAT BUILD

my @cpp_directories = (
    'examples/cpp-tutorial/stage1',
    '../stage2',
    '../stage3'
);

foreach my $cpp_directory (@cpp_directories) {
    diag '<<< DEBUG >>> have $cpp_directory = ', $cpp_directory, "\n";
    chdir $cpp_directory or die ( 'Can not change directory to ', $cpp_directory, ': \'', $!, '\'', "\n", 'stopped ' );
    diag '<<< DEBUG >>> have getcwd() = ', getcwd(), "\n";

    my Test::Alien::Run $cpp_build = run_ok([ 'bazel', 'build', '//main:hello-world' ]);
    diag '<<< DEBUG >>> have $cpp_build = ', Dumper($cpp_build), "\n";
    $cpp_build->success();
    $cpp_build->err_like(qr{INFO: Found 1 target...});
    $cpp_build->err_like(qr{Target //main:hello-world up-to-date:});
    $cpp_build->err_like(qr{bazel-bin/main/hello-world});
    $cpp_build->err_like(qr{INFO: Build completed successfully});

    my Test::Alien::Run $cpp_run = run_ok([ 'bazel-bin/main/hello-world' ]);
    diag '<<< DEBUG >>> have $cpp_run = ', Dumper($cpp_run), "\n";
    $cpp_run->success();
    $cpp_run->out_like(qr{Hello world});
    $cpp_run->out_like(qr{[A-Za-z\s]+[0-9\.]+});  # match the std::localtime() string printed on the line after "Hello world"
}

# Bazel Java Tutorial
# https://bazel.build/start/java
# 20220922 "cpp-tutorial" directory retrieved via `git clone`
# https://github.com/bazelbuild/examples/tree/main/java-tutorial

# Java, Stages X - Y
# $ cd java-tutorial
# $ bazel build //:ProjectRunner
# INFO: Found 1 target...
# Target //:ProjectRunner up-to-date:
#      bazel-bin/ProjectRunner.jar
#      bazel-bin/ProjectRunner
# INFO: Elapsed time: 2.267s, Critical Path: 0.25s
# $ bazel-bin/ProjectRunner
# ???



# START HERE: finish java tests
# START HERE: finish java tests
# START HERE: finish java tests


$JAVA_HOME = Alien::Bazel::Util->_find_jdk_java_home;
diag '<<< DEBUG >>> $JAVA_HOME = ', $JAVA_HOME, "\n";

my @java_directories = (
#    'examples/java-tutorial/stage1',
    '../../java-tutorial/',
#    '../stage2',
#    '../stage3'
);

foreach my $java_directory (@java_directories) {
    diag '<<< DEBUG >>> have $java_directory = ', $java_directory, "\n";
    chdir $java_directory or die ( 'Can not change directory to ', $java_directory, ': \'', $!, '\'', "\n", 'stopped ' );
    diag '<<< DEBUG >>> have getcwd() = ', getcwd(), "\n";

    my Test::Alien::Run $java_build = run_ok([ 'bazel', 'build', '//:ProjectRunner' ]);
    diag '<<< DEBUG >>> have $java_build = ', Dumper($java_build), "\n";
    $java_build->success();
    $java_build->err_like(qr{INFO: Found 1 target...});
    $java_build->err_like(qr{Target //:ProjectRunner up-to-date:});
    $java_build->err_like(qr{bazel-bin/ProjectRunner.jar});
    $java_build->err_like(qr{bazel-bin/ProjectRunner});
    $java_build->err_like(qr{INFO: Build completed successfully});

    my Test::Alien::Run $java_run = run_ok([ 'bazel-bin/ProjectRunner' ]);
    diag '<<< DEBUG >>> have $java_run = ', Dumper($java_run), "\n";
    $java_run->success();
    $java_run->out_like(qr{Hi!});
}

done_testing();
