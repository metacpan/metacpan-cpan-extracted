use strict;
use warnings;
use 5.008001;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    "ABSTRACT" => "Catalyst plugin for session management via headers.",
    "AUTHOR" => 'justnoxx',
    "BUILD_REQUIRES" => {},
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => "6.30",
    },
    PREREQ_PM => {
        'Moose' => 0,
        'Catalyst::Plugin::Session::State' => 0,
    },
    "DISTNAME" => "Catalyst-Plugin-Session-State-Header",
    "LICENSE" => "perl",
    "NAME" => "Catalyst::Plugin::Session::State::Header",
    "VERSION_FROM" => "lib/Catalyst/Plugin/Session/State/Header.pm",
    "test" => {
        "TESTS" => "t/*.t"
    }

);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
    my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
    my $br = $WriteMakefileArgs{BUILD_REQUIRES};
    for my $mod ( keys %$tr ) {
        if ( exists $br->{$mod} ) {
            $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
        }
        else {
            $br->{$mod} = $tr->{$mod};
        }
    }
}

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

# if so, ExtUtils::MakeMaker supports META_MERGE tag
if ($ExtUtils::MakeMaker::VERSION >= 6.46) {
    $WriteMakefileArgs{META_MERGE} = {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                web     => 'https://github.com/justnoxx/p5-catalyst-plugin-session-state-header',
                url     => 'https://github.com/justnoxx/p5-catalyst-plugin-session-state-header.git',
            },
        },
    };
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
WriteMakefile(%WriteMakefileArgs);
