#!/usr/bin/perl

use strict;
use Config;

my $modulePath = "/Alien/SmokeQt";
my ($prefix, $qmake) = ($Config{sitearch}."$modulePath");
my @cmakeArgs;
foreach my $arg (@ARGV) {
    my $key = $arg;
    my $value = $key;
    $key =~ s/=.*//g;
    $value =~ s/^[^=]*=//g;
    if ($key eq 'PREFIX' or $key eq 'INSTALL_BASE') {
        $prefix = "$value/$modulePath";
    }
    elsif ($key eq 'QMAKE') {
        $qmake = $value;
    }
    else {
        push @cmakeArgs, $arg;
    }
}

my @args;
push @args, '.';
push @args, '-DCMAKE_BUILD_TYPE=Release';
push @args, "-DCMAKE_INSTALL_PREFIX=$prefix" if $prefix;
push @args, "-DQT_QMAKE_EXECUTABLE=$qmake" if $qmake;
push @args, "-DWITH_QT3_SUPPORT=ON";
push @args, @cmakeArgs;

# Make sure we have a cmake executable
my $cmake;
foreach my $path ( split m/:/, $ENV{PATH} ) {
    if ( -e "$path/cmake" ) {
        $cmake = "$path/cmake";
        last;
    }
}
if ( !$cmake ) {
    die 'You must have cmake installed to compile Alien::SmokeQt.';
}

exit system('cmake', @args);
