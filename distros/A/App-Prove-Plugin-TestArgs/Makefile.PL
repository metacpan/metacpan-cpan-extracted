use strict;
use warnings;

use Config qw( %Config );

BEGIN {
  require './maint/AuthorExtensions.pl'
    unless ( $Config{ osname } =~ m/\A(?:freebsd|openbsd|solaris)\z/ or exists( $ENV{ MAKELEVEL } ) );
}

use ExtUtils::MakeMaker::CPANfile qw( WriteMakefile );

my %WriteMakefileArgs = (
  NAME             => 'App::Prove::Plugin::TestArgs',
  AUTHOR           => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION_FROM     => 'lib/App/Prove/Plugin/TestArgs.pm',
  ABSTRACT_FROM    => 'lib/App/Prove/Plugin/TestArgs.pod',
  LICENSE          => 'Perl_5',
  MIN_PERL_VERSION => '5.8.9',
  META_MERGE       => {
    'meta-spec' => { version => 2 },
    provides    => {
      'App::Prove::Plugin::TestArgs' => {
        file    => 'lib/App/Prove/Plugin/TestArgs.pm',
        version => '2.0.0',
      },
    },
    resources => {
      repository => {
        type => 'git',
        url  => 'git://github.com/XSven/App-Prove-Plugin-TestArgs.git',
        web  => 'https://github.com/XSven/App-Prove-Plugin-TestArgs',
      },
      bugtracker => {
        web => 'https://github.com/XSven/App-Prove-Plugin-TestArgs/issues',
      },
    },
  },
  clean     => { FILES                => 'App-Prove-Plugin-TestArgs-* cover_db' },
  dist      => { COMPRESS             => 'gzip -9f', SUFFIX => 'gz', },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 },
);

WriteMakefile( %WriteMakefileArgs );
