#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME           => 'DateTime::Format::Atom',
   AUTHOR         => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM   => 'lib/DateTime/Format/Atom.pm',
   ABSTRACT_FROM  => 'lib/DateTime/Format/Atom.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
   clean          => { FILES => 'DateTime-Format-Atom-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'unrestricted' ],

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker'       => 6.74,
            },
         },
         runtime => {
            requires => {
               'perl'                      => 5.010,
               'strict'                    => 0,
               'version'                   => 0,
               'warnings'                  => 0,
               'DateTime::Format::RFC3339' => 0,
            },
         },
         test => {
            requires => {
               'Test::More'                => 0,
            },
            recommends => {
               'Test::Pod'                 => 1.22,
            },
         },
         develop => {
            requires => {
               'Pod::Coverage'             => 0.18,
               'Test::Pod::Coverage'       => 1.08,
            },
         },
      },

      resources => {
         homepage => 'https://metacpan.org/dist/DateTime-Format-Atom',
         license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
         bugtracker => {
            web => 'https://github.com/ikegami/perl-DateTime-Format-Atom/issues',
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-DateTime-Format-Atom.git',
            web  => 'https://github.com/ikegami/perl-DateTime-Format-Atom',
         },
      },
   },
);
