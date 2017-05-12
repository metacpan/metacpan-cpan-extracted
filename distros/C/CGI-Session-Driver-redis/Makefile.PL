
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;




my %WriteMakefileArgs = (
    NAME         => 'CGI::Session::Driver::redis',
    VERSION_FROM => 'lib/CGI/Session/Driver/redis.pm',
    ABSTRACT     => 'Persistent session data in CGI applications',
    AUTHOR       => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE      => 'perl',


    PREREQ_PM => { 'CGI::Session' => 4.00,
                   'Redis'        => 0,
                 },

    TEST_REQUIRES => {

        # solely for the test-suite.
        'Test::More'      => 0,
        'Test::Pod'       => 0,
        'Test::Strict'    => 0,
        'Test::Exception' => 0,
        'Test::NoTabs'    => 0,
    },

    BUILD_REQUIRES => {
                       'File::ShareDir::Install' => 0,

        # solely for the test-suite.
        'Test::More'      => 0,
        'Test::Pod'       => 0,
        'Test::Strict'    => 0,
        'Test::Exception' => 0,
        'Test::NoTabs'    => 0,
    },


    META_MERGE => {
          resources => {
              license  => 'http://dev.perl.org/licenses/',
              homepage => 'https://github.com/skx/CGI--Session--Driver--redis/',
              bugtracker =>
                'https://github.com/skx/CGI--Session--Driver--redis/issues',
              repository =>
                'https://github.com/skx/CGI--Session--Driver--redis.git',
          },
    } );



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
