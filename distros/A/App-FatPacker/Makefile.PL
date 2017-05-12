use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

use 5.008000;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App::FatPacker',
  VERSION_FROM => 'lib/App/FatPacker.pm',

  EXE_FILES => [
    'bin/fatpack',
  ],

  META_MERGE => {
    'meta-spec' => { version => '2' },
    dynamic_config => 0,
    resources => {
      # r/w: p5sagit@git.shadowcat.co.uk:App-FatPacker.git
      repository => {
        url => 'git://git.shadowcat.co.uk/p5sagit/App-FatPacker.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/App-FatPacker.git',
        type => 'git',
      },
      bugtracker => {
          mailto => 'bug-App-FatPacker-Metadata@rt.cpan.org',
          web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-FatPacker',
      },
    },
    prereqs => {
      runtime => {
        requires => {
          # B::perlstring was added in B 1.01 (perl 5.8.0)
          perl => '5.008000',
          'B' => '1.01',
          'Cwd' => '0',
          'File::Copy' => '0',
          'File::Find' => '0',
          'File::Path' => '0',
          'File::Spec::Functions' => '0',
          'File::Spec::Unix' => '0',
          'Getopt::Long' => '0',
        },
      },
      test => {
        requires => {
          'File::Basename' => '0',
          'File::Spec' => '0',
          'File::Temp' => '0',
          'Test::More' => '0.82',
        },
      },
    },
  },
);
