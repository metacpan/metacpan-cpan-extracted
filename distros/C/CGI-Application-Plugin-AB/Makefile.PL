
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;


my %WriteMakefileArgs = (
    NAME         => 'CGI::Application::Plugin::AB',
    VERSION_FROM => 'lib/CGI/Application/Plugin/AB.pm',
    PREREQ_PM    => {
                   'CGI::Application' => 0,
                   'Redis'            => 0,
                 },

    BUILD_REQUIRES => {
        'Test::More'   => 0,
        'Test::Pod'    => 0,
        'Test::NoTabs' => 0,
    },

    ABSTRACT => 'A/B testing for CGI::Application-based applications.',
    AUTHOR   => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE  => "perl",

    MIN_PERL_VERSION => '5.008',

    META_MERGE => {
         resources => {
             license  => 'http://dev.perl.org/licenses/',
             homepage => 'https://github.com/skx/CGI--Application--Plugin--AB/',
             bugtracker =>
               'https://github.com/skx/CGI--Application--Plugin--AB/issues',
             repository =>
               'https://github.com/skx/CGI--Application--Plugin--AB.git',
             GitMirror =>
               'http://git.steve.org.uk/cpan/CGI--Application--Plugin--AB',
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
