#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw( WriteMakefile );

WriteMakefile(
   NAME          => 'DateTime::Format::RFC3339',
   AUTHOR        => 'Eric Brine <ikegami@adaelis.com>',
   VERSION_FROM  => 'lib/DateTime/Format/RFC3339.pm',
   ABSTRACT_FROM => 'lib/DateTime/Format/RFC3339.pm',
   dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
   clean          => { FILES => 'DateTime-Format-Atom-*' },
   BUILD_REQUIRES => {},

   META_MERGE  => {
      'meta-spec' => { version => 2 },

      license => [ 'unrestricted' ],

      prereqs => {
         configure => {
            requires => {
               'ExtUtils::MakeMaker' => 6.52,
            },
         },
         runtime => {
            requires => {
               'strict'              => 0,
               'version'             => 0,
               'warnings'            => 0,
               'DateTime'            => 0,
            },
         },
         test => {
            requires => {
               'Test::More'          => 0,
            },
            recommends => {
               'Test::Pod'           => 1.22,
            },
         },
         develop => {
            requires => {
               'FindBin'             => 0,
               'Pod::Coverage'       => 0.18,
               'Test::Pod::Coverage' => 1.08,
            },
         },
      },

      resources => {
         homepage => 'http://search.cpan.org/dist/DateTime-Format-RFC3339/',
         license => [ 'http://creativecommons.org/publicdomain/zero/1.0/' ],
         bugtracker => {
            web    => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Format-RFC3339',
            mailto => 'bug-DateTime-Format-RFC3339@rt.cpan.org',
         },
         repository => {
            type => 'git',
            url  => 'https://github.com/ikegami/perl-DateTime-Format-RFC3339.git',
            web  => 'https://github.com/ikegami/perl-DateTime-Format-RFC3339',
         },
      },
   },
);
