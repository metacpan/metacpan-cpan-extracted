#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'D64::Disk::Image',
    VERSION_FROM      => 'lib/D64/Disk/Image.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (AUTHOR         => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
    DEFINE            => '',
    OBJECT            => 'Image.o diskimage.o',
    OPTIMIZE          => '-O2',
);
