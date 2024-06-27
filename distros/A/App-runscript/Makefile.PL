use strict;
use warnings;

use Config qw( %Config );

BEGIN {
  require './maint/AuthorExtensions.pl'
    unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) );
}

use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME             => 'App::runscript',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => 'lib/App/runscript.pm',
  ABSTRACT_FROM    => 'lib/App/runscript.pod',
  EXE_FILES        => [ qw( bin/runscript ) ],
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.8.9',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'App::runscript' => {
        file    => 'lib/App/runscript.pm',
        version => '1.0.2',
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/App-runscript.git',
        web  => 'https://github.com/XSven/App-runscript',
      },
      bugtracker => {
        web => 'https://github.com/XSven/App-runscript/issues',
      },
    },
  },
  clean     => { FILES                => 'App-runscript-* cover_db' },
  dist      => { COMPRESS             => 'gzip -9f', SUFFIX => 'gz', },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 },
);

WriteMakefile( %WriteMakefileArgs );
