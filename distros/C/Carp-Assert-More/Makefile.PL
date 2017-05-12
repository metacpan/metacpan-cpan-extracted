package main;

use 5.006001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %parms = (
    NAME                => 'Carp::Assert::More',
    VERSION_FROM        => 'More.pm', # finds $VERSION

    PM => {
        'More.pm'       => '$(INST_LIB)/Carp/Assert/More.pm',
    },

    PREREQ_PM   => {
        Carp                => 0,
        'Carp::Assert'      => 0,
        'Scalar::Util'      => 0,
        'Test::Exception'   => 0,
        'Test::More'        => 0.18,
    },

    dist => {
        COMPRESS        => 'gzip -9',
        SUFFIX          => '.gz',
        DIST_DEFAULT    => 'all tardist',
    },
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
    $parms{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $parms{META_MERGE} = {
        resources => {
            bugtracker  => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Carp-Assert-More',
            repository  => 'http://github.com/petdance/carp-assert-more/tree/master',
            license     => 'http://www.opensource.org/licenses/artistic-license-2.0.php',
        }
    };
}

WriteMakefile( %parms );

package MY;

sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';
.PHONY: critic

critic:
	perlcritic -1 -q -profile perlcriticrc More.pm t/*.t

MAKE_FRAG

    return $postamble;
}

1;
