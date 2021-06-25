use 5.024;
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'DataStructure',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/DataStructure.pm',
    ABSTRACT         => 'Collection of useful data-structures in pure Perl',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.024',
    MAN3PODS         => {},
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/perl-datastructure.git',
          web => 'https://github.com/mkende/perl-datastructure',
        },
        bugtracker => {
          web => 'https://github.com/mkende/perl-datastructure/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DataStructure-*' },
);
