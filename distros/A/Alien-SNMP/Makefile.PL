#!/usr/bin/env perl

use strict;
use warnings;
use 5.010001;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

# Windows is not supported (Net-SNMP source build); bail early, matching the old
# inc/My/ModuleBuild.pm behavior.
if ($^O eq 'MSWin32') {
  print "OS not supported\n";
  exit;
}

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
  NAME          => 'Alien::SNMP',
  DISTNAME      => 'Alien-SNMP',
  VERSION_FROM  => 'lib/Alien/SNMP.pm',
  ABSTRACT      => 'Build and install Net-SNMP',
  AUTHOR        => 'Eric A. Miller <emiller AT cpan DOT org>',
  LICENSE       => 'bsd',
  MIN_PERL_VERSION => '5.010001',

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.30',
    'Alien::Build::MM'    => '2.84',  # pulls in Alien::Build + the bundled plugins
    'Alien::Build'        => '2.84',  # digest directive + Download/Extract/Autoconf plugins
  },
  BUILD_REQUIRES => {
    'Alien::Build' => '2.84',        # source build: Download/Extract/Autoconf + digest
  },
  PREREQ_PM => {
    'Alien::Base' => '2.84',
  },
  TEST_REQUIRES => {
    'Test::Alien' => '2.84',
    'Test::More'  => '0.94',
  },

  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources   => {
      repository => {
        type => 'git',
        url  => 'https://github.com/ollyg/Alien-SNMP.git',
        web  => 'https://github.com/ollyg/Alien-SNMP',
      },
      bugtracker => { web => 'https://github.com/ollyg/Alien-SNMP/issues' },
    },
  },
));

# Wire Alien::Build::MM into the standard MakeMaker targets, and add author-only
# LICENSE/README regeneration (replacing Module::Build's create_license/create_readme).
# Gated on a git checkout so the rules never appear in the shipped tarball and
# installers need no Software::License / Pod::Text.
sub MY::postamble {
  my $postamble = $abmm->mm_postamble;   # REQUIRED: injects the alien_* targets
  if (-d '.git' || $ENV{AUTHOR_TESTING}) {
    $postamble .= <<'MAKE';

README : lib/Alien/SNMP.pm
	$(PERLRUN) -MPod::Text -e "Pod::Text->new->parse_from_file(q[lib/Alien/SNMP.pm], q[README])"

LICENSE :
	$(PERLRUN) -MSoftware::License::BSD -e "print Software::License::BSD->new({holder=>q[Eric A. Miller], year=>2026})->fulltext" > LICENSE

regen-meta : README LICENSE
MAKE
  }
  return $postamble;
}
