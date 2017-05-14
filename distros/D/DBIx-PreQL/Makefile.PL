use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    'ABSTRACT' => 'Less terrible dynamic SQL',
    'AUTHOR' => 'Mark Swayne <daotoad@cpan.org>',
    'BUILD_REQUIRES' => {
        'Data::Dumper' => '0',
        'Test::More'   => '0',
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.30'
    },
    'DISTNAME' => 'DBIx-PreQL',
    'EXE_FILES' => [],
    'LICENSE' => 'perl',
    'NAME' => 'DBIx::PreQL',
    'PREREQ_PM' => {
        'B' => '0',
        'Carp' => '0',
    },
    'VERSION' => '0.01.00',
    'test' => {
        'TESTS' => 't/*.t'
    }
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod ( keys %$br ) {
        if ( exists $pp->{$mod} ) {
            $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
        }
        else {
            $pp->{$mod} = $br->{$mod};
        }
    }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



