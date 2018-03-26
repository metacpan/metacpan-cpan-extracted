use ExtUtils::MakeMaker;

use strict;
use warnings;

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
    'DT'          => '0.3.0',
    'DBIx::Class' => '0.082840',
);

WriteMakefile(
    NAME         => 'DBIx::Class::InflateColumn::DT',
    VERSION_FROM => 'lib/DBIx/Class/InflateColumn/DT.pm',
    ABSTRACT     => 'DBIx::Class column inflator into DT objects',
    AUTHOR       => 'Alex Tokarev',
    LICENSE      => 'perl',
    PREREQ_PM     => \%MAIN_REQ,

    META_MERGE => {
        resources => {
            bugtracker => 'https://github.com/nohuhu/DBIx-Class-InflateColumn-DT/issues',
            repository => {
                url => 'git://git@github.com:nohuhu/DBIx-Class-InflateColumn-DT.git',
                web => 'https://github.com/nohuhu/DBIx-Class-InflateColumn-DT',
                type => 'git',
            },
        },
    },
);

