# generate Makefile for building Data::PowerSet
#
# Copyright (C) 2005-2008 David Landgren

use strict;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";
if( !$@ ) {
    print "Adding testcover target\n";
}

my @license =
    do {
        my $version = $ExtUtils::MakeMaker::VERSION;
        $version =~ tr/_//d;
        $version
    } > 6.30
    ? qw(LICENSE perl)
    : ();

WriteMakefile(
    NAME          => 'Data::PowerSet',
    VERSION_FROM  => 'PowerSet.pm',
    ABSTRACT_FROM => 'PowerSet.pm',
    AUTHOR        => 'David Landgren',
    @license,
);
