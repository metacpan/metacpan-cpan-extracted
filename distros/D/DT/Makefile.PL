use ExtUtils::MakeMaker;

use strict;
use warnings FATAL => 'all';

# Add the `devtest` target to run regression and POD tests in one go
# Beware the unexpanded tabs in this block!
sub MY::postamble {
    return <<'END';
devtest :
	REGRESSION_TESTS=1 POD_TESTS=1 $(MAKE) test

END
}

# Override `disttest` so it would behave as `devtest`
# Beware the unexpanded tabs in this block!
sub MY::dist_test {
    return <<'END';
disttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) devtest $(PASTHRU)

END
}

my %MAIN_REQ = (
    'parent'                            => '0.236',
    'Scalar::Util'                      => 0,
    'DateTime::Moonpig'                 => '1.03',
    'DateTime::Format::ISO8601'         => '0.08',
    'DateTime::Format::ISO8601::Format' => '0.003',
);

WriteMakefile(
    NAME         => 'DT',
    VERSION_FROM => 'lib/DT.pm',
    ABSTRACT     => 'DWIM wrapper for DateTime',
    AUTHOR       => 'Alex Tokarev',
    LICENSE      => 'perl',
    PREREQ_PM     => \%MAIN_REQ,

    META_MERGE => {
        resources => {
            bugtracker => 'https://github.com/nohuhu/DT/issues',
            repository => {
                url => 'git://git@github.com:nohuhu/DT.git',
                web => 'https://github.com/nohuhu/DT',
                type => 'git',
            },
        },
    },
);

