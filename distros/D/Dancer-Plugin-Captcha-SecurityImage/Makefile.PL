use strict;
use warnings;

use ExtUtils::MakeMaker 6.31;

my %WriteMakefileArgs = (
    'ABSTRACT' => 'Integration with GD::SecurityImage for your Dancer apps',
    'AUTHOR' => 'Alessandro Ranellucci <aar@cpan.org>',
    'BUILD_REQUIRES' => {
        'Dancer' => '1.200',
    },
    'CONFIGURE_REQUIRES' => {
        'ExtUtils::MakeMaker' => '6.31'
    },
    'DISTNAME' => 'Dancer-Plugin-Captcha-SecurityImage',
    'EXE_FILES' => [],
    'LICENSE' => 'perl',
    'NAME' => 'Dancer::Plugin::Captcha::SecurityImage',
    'PREREQ_PM' => {
        'Dancer' => '1.200',
        'GD::SecurityImage' => 0,
    },
    'VERSION' => '0.10',
    'test' => {
        'TESTS' => 't/*.t'
    },
    'META_MERGE' => {
        resources => {
            repository => 'git://git@github.com:alexrj/Dancer-Plugin-Captcha-SecurityImage.git',
        },
    },
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
    my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
    my $pp = $WriteMakefileArgs{PREREQ_PM};
    for my $mod (keys %$br) {
        if (exists $pp->{$mod}) {
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
