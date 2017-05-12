use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'Array::Sticky',
  AUTHOR              => q{Belden Lyman <belden@cpan.org>},
  VERSION_FROM        => 'lib/Array/Sticky.pm',
  ABSTRACT            => 'Make elements of an array stick where they are',
  LICENSE => 'perl',
  PL_FILES            => {},
  META_MERGE => {
    resources => {
      repository => 'git://github.com/belden/perl-array-sticky.git',
      homepage   => 'https://github.com/belden/perl-array-sticky',
      bugtracker => 'https://github.com/belden/perl-array-sticky/issues',
    },
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
