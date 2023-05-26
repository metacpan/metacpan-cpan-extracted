use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

WriteMakefile(
  'ABSTRACT_FROM' => 'lib/Date/ICal.pm',
  'AUTHOR'       => 'Rich Bowen <rbow@cpan.org>',
  'NAME'         => 'Date::ICal',
  'LICENSE'      => 'perl',
  ($EUMM_VERSION >= 6.48) ? ('MIN_PERL_VERSION' => 5.006000) : (),
  'VERSION_FROM' => 'lib/Date/ICal.pm',    # finds $VERSION
  'PREREQ_PM'    => {
      'Test::Harness' => '2.25',
      'Test::More'    => '0.45',
      'Date::Leapyear' => '1.03',
      'Time::Local'    => 0,
      'Time::HiRes'    => 0,
      'Storable'       => 0,
  },
  META_MERGE => {
      'meta-spec' => { version => 2 },
       resources => {
           repository => {
               type => 'git',
               url  => 'https://github.com/michal-josef-spacek/Date-ICal.git',
               web  => 'https://github.com/michal-josef-spacek/Date-ICal',
           },
           bugtracker => {
               web => 'https://github.com/michal-josef-spacek/Date-ICal/issues'
           },
       },
  },
);

sub MY::postamble {
    package MY;
    "\npredist: all\n" .
    "\tpod2text lib/Date/ICal.pm >! README\n".
    "\techo '------------------------------------------------' >> README\n".
    "\tpod2text lib/Date/ICal/Duration.pm >> README\n"
}

