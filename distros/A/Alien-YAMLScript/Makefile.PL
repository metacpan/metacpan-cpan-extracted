use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  NAME => 'Alien::YAMLScript',
  DISTNAME => 'Alien-YAMLScript',
  VERSION_FROM => 'lib/Alien/YAMLScript.pm',
  ABSTRACT => 'YAMLScript shared library',
  AUTHOR => 'Ingy dot Net <ingy@ingy.net>',
  LICENSE => 'mit',
  MIN_PERL_VERSION => '5.016',
  CONFIGURE_REQUIRES => {
    'Alien::Build' => '2.80',
    'Alien::Build::MM' => '2.80',
    'Alien::Build::Plugin::Download::GitHub' => '0.10',
    'ExtUtils::MakeMaker' => '0',
  },
  PREREQ_PM => {
    'Alien::Base' => '0',
    'Cpanel::JSON::XS' => '4.37',
    'Mozilla::CA' => '0',
  },
  TEST_REQUIRES => {
    'Test2::V0' => '0.000159',
    'Test::Alien' => '2.80',
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      bugtracker => {
        web => 'https://github.com/yaml/yamlscript/issues',
      },
      homepage => 'https://yamlscript.org',
      repository => {
        type => 'git',
        url => 'https://github.com/yaml/yamlscript.git',
        web => 'https://github.com/yaml/yamlscript',
      },
    },
  },
));

sub MY::postamble {
  $abmm->mm_postamble(@_);
}

sub MY::install {
  $abmm->mm_install(@_);
}
