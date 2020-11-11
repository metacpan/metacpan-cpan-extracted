
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.64;


my %WriteMakefileArgs = (
    NAME         => 'CGI::Application::Plugin::Throttle',
    VERSION_FROM => 'lib/CGI/Application/Plugin/Throttle.pm',

    PREREQ_PM => {
        'Digest::SHA'                   => 5.6,
    },

    TEST_REQUIRES => {
        'CGI::Application'              => 0,
        'File::Find'                    => 0,
        'Test::CheckManifest'           => 0.9,
        'Test::Mock::Redis'             => 0,
        'Test::More'                    => 0,
        'Test::NoTabs'                  => 0,
        'Test::Pod'                     => 0,
        'Test::Strict'                  => 0,
        'Test::Time'                    => 0,
        'Test::WWW::Mechanize::CGIApp'  => 0,
    },

    ABSTRACT => 'Rate-Limiting for CGI::Application.',
    AUTHOR   => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE  => "perl",

    MIN_PERL_VERSION => '5.008',

    META_MERGE => {
         resources => {
             license  => 'http://dev.perl.org/licenses/',
             homepage => 'https://github.com/skx/CGI--Application--Plugin--Throttle/',
             bugtracker =>
               'https://github.com/skx/CGI--Application--Plugin--Throttle/issues',
             repository =>
               'https://github.com/skx/CGI--Application--Plugin--Throttle.git',
         },
    },
);



unless ( eval {ExtUtils::MakeMaker->VERSION(6.56)} )
{
    my $br = delete $WriteMakefileArgs{ BUILD_REQUIRES };
    my $pp = $WriteMakefileArgs{ PREREQ_PM };
    for my $mod ( keys %$br )
    {
        if ( exists $pp->{ $mod } )
        {
            $pp->{ $mod } = $br->{ $mod } if $br->{ $mod } > $pp->{ $mod };
        }
        else
        {
            $pp->{ $mod } = $br->{ $mod };
        }
    }
}

delete $WriteMakefileArgs{ CONFIGURE_REQUIRES }
  unless eval {ExtUtils::MakeMaker->VERSION(6.52)};

WriteMakefile(%WriteMakefileArgs);
