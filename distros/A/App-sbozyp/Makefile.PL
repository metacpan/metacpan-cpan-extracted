use strict;
use warnings;

use v5.34.0;

use ExtUtils::MakeMaker;

sub MY::manifypods {
    return <<'END_MANFIFYPODS'

POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)


manifypods : pure_all config  \
	bin/sbozyp \
	lib/App/sbozyp.pm
	$(NOECHO) $(POD2MAN) --section=$(MAN1SECTION) --perm_rw=$(PERM_RW) -u \
      -c '' -r sbozyp-$(VERSION) \
	  bin/sbozyp $(INST_MAN1DIR)/sbozyp.$(MAN1EXT)
END_MANFIFYPODS
}

WriteMakefile(
    NAME         => 'App::sbozyp',
    DISTNAME     => 'App-sbozyp',
    AUTHOR       => 'Nicholas Hubbard <nicholashubbard@posteo.net>',
    ABSTRACT     => q(a package manager for Slackware's SlackBuilds.org),
    LICENSE      => 'gpl_3',
    VERSION_FROM => 'bin/sbozyp',
    MIN_PERL_VERSION => '5.34.0',

    EXE_FILES => [
        'bin/sbozyp'
    ],

    # No non-core dependencies
    PREREQ_PM => {},

    META_MERGE => {
        resources => {
            repository  => 'https://github.com/NicholasBHubbard/sbozyp',
            bugtracker  => 'https://github.com/NicholasBHubbard/sbozyp/issues',
        },
    },
);
