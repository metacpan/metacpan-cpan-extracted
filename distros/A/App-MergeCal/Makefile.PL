use strict;
use warnings;

use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer release/version
  $mm_ver = eval { $mm_ver };
  die $@ if $@;
}

WriteMakefile(
  NAME         => 'App::MergeCal',
  VERSION_FROM => 'lib/App/MergeCal.pm',
  LICENSE      => 'perl_5',

  EXE_FILES    => [ 'bin/mergecal' ],

  PREREQ_PM    => {
    ($^V lt v5.38 ? ('Object::Pad' => 0) : ()),
    'Feature::Compat::Class' => 0,
    'Text::vFile::asData'    => 0,
    'LWP::Simple'            => 0,
    'JSON'                   => 0,
  },
  TEST_REQUIRES => {
    'Test::More' => 0,
  },

  META_MERGE    => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/davorg-cpan/app-mergecal.git',
        web  => 'https://github.com/davorg-cpan/app-mergecal',
      },
      bugtracker => {
        web  => 'https://github.com/davorg-cpan/app-mergecal/issues',
      },
    },
  },
  ($mm_ver >= 6.48
    ? (MIN_PERL_VERSION => 5.014)
    : ()
  ),
);
