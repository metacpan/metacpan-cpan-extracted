## This -*- perl -*- script writes the Makefile for AutoLoader
# You should read "perldoc perlmodinstall" for instructions on
#  how to install modules like this.

require 5.006001;
use strict;
use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME' => 'AutoLoader',
  'VERSION_FROM' => 'lib/AutoLoader.pm', # finds $VERSION
  'LICENSE' => 'perl',
  'PREREQ_PM' => {},
  'ABSTRACT_FROM' => 'lib/AutoLoader.pm',
  'AUTHOR' => 'Steffen Mueller <smueller@cpan.org>',
  'INSTALLDIRS' => ($] < 5.012 ? 'perl' : 'site'),
  META_MERGE => {
      resources => {
          bugtracker  => 'http://rt.perl.org/perlbug/',
          MailingList => 'http://lists.cpan.org/showlist.cgi?name=perl5-porters'
      },
  }
);

__END__

