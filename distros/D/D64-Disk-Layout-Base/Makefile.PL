#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'D64::Disk::Layout::Base',
    VERSION_FROM      => 'lib/D64/Disk/Layout/Base.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (AUTHOR         => 'Pawel Krol <pawelkrol@cpan.org>') : ()),
    DEFINE            => '',
    OPTIMIZE          => '-O2',
);
