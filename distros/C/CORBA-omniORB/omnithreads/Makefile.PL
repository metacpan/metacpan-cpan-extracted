# Module makefile for omnithreads (using ExtUtils::MakeMaker)

require 5.008;

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

my $CC;
my $CCFLAGS = '';
my $OPTIMIZE = '';
my $DEFINE = '-DHAS_PPPORT_H';
my $OMNITHREADINC;
my $OMNITHREADLIBS;
my $LDDLFLAGS;
my $XSOPT = "-C++";

if ($Config{'osname'} eq "MSWin32") {
    my $Win32Config = ReadConfFile ('../CONFIG.win32')
        or die ("Failed to open file '../CONFIG.win32'");

    my $OMNIORBPREFIX = $Win32Config->{'OMNIORBPREFIX'};

    # try to locate omniORB lib
    my $omniorblibpath = "$OMNIORBPREFIX/lib/x86_win32/";

    $OMNITHREADINC = "-I$OMNIORBPREFIX/include";
    $OMNITHREADLIBS = [ "-L$omniorblibpath " . $Win32Config->{'OMNIORBLIBS'} ];
    $CCFLAGS    = $Win32Config->{'CCFLAGS'};
    $OPTIMIZE   = $Win32Config->{'OPTIMIZE'};
    $LDDLFLAGS  = $Win32Config->{'LDDLFLAGS'};
    $DEFINE     = $Win32Config->{'DEFINE'} . " -DHAS_PPPORT_H";
    $XSOPT      = $Win32Config->{'XSOPT'};
}
else {
    $CC = 'g++';
    $OMNITHREADINC    = `pkg-config --cflags omnithread3`;
    chomp $OMNITHREADINC;
    $OMNITHREADLIBS   = `pkg-config --libs omnithread3`;
    chomp $OMNITHREADLIBS;
}

# Create Makefile
WriteMakefile(
    'NAME'              => 'omnithreads',
    'AUTHOR'            => 'Artur Bergman <sky AT crucially DOT net>',
    'VERSION_FROM'      => 'omnithreads.pm',
    'ABSTRACT_FROM'     => 'omnithreads.pm',
    'PM' => {
        'omnithreads.pm' => '$(INST_LIBDIR)/omnithreads.pm',
    },
    'PREREQ_PM'         => {
        'XSLoader'        => 0,
    },
    'DEFINE'            => $DEFINE,
    'LIBS'              => $OMNITHREADLIBS,   
    'INC'               => $OMNITHREADINC,

    'CC'		=> $CC,
    'CCFLAGS'           => $CCFLAGS,
    'OPTIMIZE'          => $OPTIMIZE,
    'XSOPT'             => $XSOPT,

    ((ExtUtils::MakeMaker->VERSION() lt '6.25') ?
        ('PL_FILES' => { })            : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),
);

# EOF
