#!/usr/bin/env perl
use 5.10.1;
use warnings;
use strict;
use ExtUtils::MakeMaker 6.64;

my $preop = 'perldoc -uT $(VERSION_FROM) | tee README.pod';

WriteMakefile(
  NAME             => 'Catalyst::Action::Serialize::SimpleXLSX',
  AUTHOR           => 'Mike Baas <mbaas@cpan.org>',
  MIN_PERL_VERSION => 5.10.1,
  VERSION_FROM     => 'lib/Catalyst/Action/Serialize/SimpleXLSX.pm',
  ABSTRACT_FROM    => 'lib/Catalyst/Action/Serialize/SimpleXLSX.pm',
  ($ExtUtils::MakeMaker::VERSION >= 6.64 ? ('LICENSE'=> 'perl') : ()),
  PL_FILES => {},
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.64,
  },
  BUILD_REQUIRES => {
    'Template' => 0,
  },
  PREREQ_PM => {
    'Catalyst::Controller::REST' => 0,
    'Catalyst::Exception' => 0,
    'Excel::Writer::XLSX' => 0,
    'namespace::clean' => 0,
  },
  TEST_REQUIRES => {
    'Test::More' => 0.88,
    'Test::Deep' => 0,
    'Spreadsheet::XLSX' => 0,
    'File::Temp' => 0,
  },
  dist => {
    COMPRESS => 'gzip -9f',
    SUFFIX => 'gz',
    PREOP => $preop,
  },
  clean => { FILES => 'Catalyst-Action-Serialize-SimpleXLSX-*' },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/initself/Catalyst-Action-Serialize-SimpleXLSX.git',
        web  => 'https://github.com/initself/Catalyst-Action-Serialize-SimpleXLSX',
      },
    },
  },
);


