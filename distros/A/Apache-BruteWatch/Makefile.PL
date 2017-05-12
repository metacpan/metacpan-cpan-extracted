use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
## Please see file perltidy.ERR
WriteMakefile(
    NAME         => 'Apache::BruteWatch',
    VERSION_FROM => 'lib/Apache/BruteWatch.pm',          # finds $VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT     =>
      'Watch the Apache logs and notify of bruteforce password attacks',
    PREREQ_PM => {
        Test::More        => 0,
        Mail::Sendmail    => 0,
        DBI               => 0,
        Apache::Constants => 0,
    },
);

