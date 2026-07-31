#!/usr/bin/env perl

use strict;
use warnings;
use 5.010001;
use ExtUtils::MakeMaker;
use File::Spec;
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

# Point the dynamic loader at the staged libnetsnmp for the test phase, and only
# the test phase.  Alien::SNMP preloads that library at use-time so the bundled XS
# resolves it before `make install` has populated the final share dir, which is
# where the run-path baked into the XS points.  That works on glibc, which matches
# an already-loaded object by its DT_SONAME, and on darwin, which matches by
# install name.  It cannot work on musl: opening a library by an explicit path
# records no name for it at all (ldso/dynlink.c, "Add a shortname only if name arg
# was not an explicit pathname"), and the already-loaded lookup matches on that
# name alone, so on Alpine every load of the bundled modules fails with "Error
# loading shared library libnetsnmp.so.45".
# Nothing installed is affected: this alters one make recipe, and the installed
# copy resolves through the run-path as before.
# Written as a package block, not `sub MY::test_via_harness`: SUPER:: resolves
# against the package a sub is compiled in, which for the latter is main.
{
  package MY;

  sub test_via_harness {
    my ($self, $perl, $tests) = @_;
    # Absolute: a relative entry in LD_LIBRARY_PATH resolves against the current
    # directory, and Test::Alien compiles and loads its XS somewhere else.
    my $staged_libs = File::Spec->rel2abs(File::Spec->catdir(
      $self->{INST_LIB}, qw(auto share dist), $self->{DISTNAME}, 'lib'));
    return $self->SUPER::test_via_harness(
      qq{LD_LIBRARY_PATH="$staged_libs:\$\$LD_LIBRARY_PATH" $perl}, $tests);
  }
}

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
