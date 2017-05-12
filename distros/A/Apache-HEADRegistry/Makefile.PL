#!perl

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Apache::HEADRegistry',
  VERSION_FROM => 'HEADRegistry.pm',
  PREREQ_PM    => { mod_perl => 1.26, },
  ABSTRACT     => 'Apache::Registry that handles HEAD requests',
  AUTHOR       => 'geoff@cpan.org',
  %config,
);

sub MY::test {
  eval {
    require Apache::Test;
    require Apache::TestMM;
    require Apache::TestRunPerl;

    Apache::TestMM->import(qw(test clean));
    Apache::TestMM::filter_args();

    Apache::TestRunPerl->generate_script();

    return Apache::TestMM->test;
  }

  or return <<EOF;
test::
\t\@echo This test suite requires Apache-Test,
\t\@echo which is available from the mod_perl 2.0 
\t\@echo sources, CPAN, or the httpd-test distribution.
EOF
}
