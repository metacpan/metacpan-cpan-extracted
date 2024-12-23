package main;

use 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker 6.46;

my %parms = (
    NAME                => 'Carp::Assert::More',
    VERSION_FROM        => 'More.pm', # finds $VERSION
    LICENSE             => 'artistic_2',
    MIN_PERL_VERSION    => '5.10.1',

    PM => {
        'More.pm'       => '$(INST_LIB)/Carp/Assert/More.pm',
    },

    PREREQ_PM   => {
        Carp                => 0,
        'Scalar::Util'      => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0.18,
    },

    dist => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
        DIST_DEFAULT    => 'all tardist',
    },

    META_MERGE => {
        resources => {
            homepage    => 'https://github.com/petdance/carp-assert-more',
            bugtracker  => 'https://github.com/petdance/carp-assert-more/issues',
            repository  => 'git@github.com:petdance/carp-assert-more.git',
            license     => 'https://opensource.org/licenses/artistic-license-2.0.php',
        }
    },
);

WriteMakefile( %parms );

package MY;

sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';
.PHONY: critic tags

critic:
	perlcritic -1 -q -profile perlcriticrc More.pm t/*.t

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib \
		--exclude=.git \
		--exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \

MAKE_FRAG

    return $postamble;
}

1;
