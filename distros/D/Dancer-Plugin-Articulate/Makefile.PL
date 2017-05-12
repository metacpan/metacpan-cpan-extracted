use strict;
use warnings;
use ExtUtils::MakeMaker;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
  NAME         => 'Dancer::Plugin::Articulate',
  AUTHOR       => q{Daniel Perrett <perrettdl@googlemail.com>},
  VERSION_FROM => 'lib/Dancer/Plugin/Articulate.pm',
  ABSTRACT     => 'Dancer interface to a lightweight Perl CMS Framework',
  (
    $eumm_version >= 6.3001
    ? ( 'LICENSE' => 'perl' )
    : ()
  ),
  META_MERGE => {
    resources => {
      repository => 'http://github.com/pdl/Articulate',
      bugtracker => 'http://github.com/pdl/Articulate/issues',
      homepage   => 'http://github.com/pdl/Articulate',
    },
  },
  MIN_PERL_VERSION => 5.010_001,
  PL_FILES         => {},
  PREREQ_PM        => {
    'Articulate' => 0,
    'Dancer'     => 1.3118,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Articulate-*' },
);
