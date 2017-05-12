# generate Makefile for building BSD::Process
#
# Copyright (C) 2006-2011 David Landgren

use strict;
use ExtUtils::MakeMaker;
use Config;

my $module_name = 'BSD::Process';

if ($Config{osname} ne 'freebsd') {
    die "OS unsupported ($Config{osname}). Here's a nickel, go buy yourself a real OS.\n";
}

eval "use ExtUtils::MakeMaker::Coverage" and print "Adding testcover target\n";

my @license =
    do {
        my $version = $ExtUtils::MakeMaker::VERSION;
        $version =~ tr/_//d;
        $version} > 6.30
    ? qw(LICENSE perl)
    : ();

WriteMakefile(
    NAME          => $module_name,
    ABSTRACT_FROM => 'Process.pm',
    VERSION_FROM  => 'Process.pm',
    AUTHOR        => 'David Landgren',
    LIBS          => ['-lkvm'],
    @license,
    PREREQ_PM     => {
        'XSLoader'        => 0,
        'Class::Accessor' => '0.25',
    },
    MIN_PERL_VERSION => '5.008001'
);
