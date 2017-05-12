use strict;
use warnings;
use 5.008001;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    ABSTRACT    => 'AnyEvent::ConnPool adapter for AnyEvent::MySQL',
    AUTHOR      => 'justnoxx',
    DISTNAME    => 'AnyEvent-MySQL-ConnPool',
    LICENSE     => 'perl',
    NAME        => 'AnyEvent::MySQL::ConnPool',
    VERSION_FROM => "lib/AnyEvent/MySQL/ConnPool.pm",
    CONFIGURE_REQUIRES  => {
        'AnyEvent'            =>    7.07,
        'AnyEvent::ConnPool'  =>    0.07,
        'AnyEvent::MySQL'     =>    0,
        'ExtUtils::MakeMaker' =>    6.30,
    },
    BUILD_REQUIRES      => {
        'AnyEvent'            =>    7.07,
        'AnyEvent::ConnPool'  =>    0.07,
        'AnyEvent::MySQL'     =>    0,
        'ExtUtils::MakeMaker' =>    6.30,
    },  
    PREREQ_PM           => {
        'AnyEvent'            =>    7.07,
        'AnyEvent::ConnPool'  =>    0.07,
        'AnyEvent::MySQL'     =>    0,
        'ExtUtils::MakeMaker' =>    6.30,
    },
    TEST_REQUIRES       => {
        'AnyEvent'            =>    7.07,
        'AnyEvent::ConnPool'  =>    0.07,
        'AnyEvent::MySQL'     =>    0,
        'ExtUtils::MakeMaker' =>    6.30,
    },
    test => {
        TESTS => "t/*.t"
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
                web     => 'https://github.com/justnoxx/anyevent-mysql-connpool',
                url     => 'https://github.com/justnoxx/anyevent-mysql-connpool.git',
            },
        },
    };
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES} unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
WriteMakefile(%WriteMakefileArgs);
