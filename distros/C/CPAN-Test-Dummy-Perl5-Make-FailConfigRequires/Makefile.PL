use strict;
use ExtUtils::MakeMaker;

print << 'HERE';

This Makefile.PL of CPAN::Test::Dummy::Perl5::Make::FailConfigRequires
demonstrates what happens when a distribution has an unsatisfied
configure_requires in META.yml

This can be avoided by touching a file 'SURVIVE' in the current
directory.

HERE

require Impossible::Requirement::Missing unless -f "SURVIVE";

WriteMakefile(
  NAME          => 'CPAN::Test::Dummy::Perl5::Make::FailConfigRequires',
  VERSION_FROM  => _f('./lib/CPAN/Test/Dummy/Perl5/Make/FailConfigRequires.pm'),
  ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
    (LICENSE      => "perl") : (),
  ),
  ABSTRACT      => 'CPAN Test Dummy for CPAN.pm',
  PL_FILES      => {},
);

