use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
      NAME          => 'Config::YAML::Tiny',
      AUTHOR        => 'Timothy Appnel <tima@cpan.org>',
      VERSION_FROM  => 'lib/Config/YAML/Tiny.pm',
      ABSTRACT_FROM => 'lib/Config/YAML/Tiny.pm',
      PL_FILES      => {},
      PREREQ_PM     => { 'Test::More' => 0, 'YAML::Tiny' => 1.12, },
      META_MERGE    => {
          resources =>
            { repository => 'http://github.com/tima/perl-config-yaml-tiny', },
      },
      LICENSE => 'perl',
      dist    => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
      clean => { FILES => 'Config-YAML-*' },
);
