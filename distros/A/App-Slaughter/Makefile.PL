use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
    NAME         => 'App::Slaughter',
    VERSION_FROM => 'lib/Slaughter.pm',
    EXE_FILES    => ['bin/slaughter'],
    PREREQ_PM    => {
        'File::Basename'  => 0,
        'File::Find'      => 0,
        'File::Path'      => 0,
        'File::Spec'      => 0,
        'File::Temp'      => 0,
        'Getopt::Long'    => 0,
        'Pod::Usage'      => 0,
        "POSIX"           => 0,

        # non-core modules
        'LWP::UserAgent'  => 0,
        "Text::Template"  => 0,
        "Mojo::UserAgent" => 0,
        },
    TEST_REQUIRES => {
        # solely for the test-suite.
        'Test::More'   => 0,
        'Test::Pod'    => 0,
        'Test::Strict' => 0,
        'Test::NoTabs' => 0,
        'Test::Script' => 0,
        'Test::Exception' => 0,
        'Test::File::Contents' => 0,
        'Capture::Tiny' => 0,
                 },
    ABSTRACT => 'The Slaughter System Administration Utility.',
    AUTHOR   => 'Steve Kemp <steve@steve.org.uk>',
    LICENSE  => 'perl',

    MIN_PERL_VERSION => '5.008',

    META_MERGE => {
                    resources => {
                        license    => 'http://dev.perl.org/licenses/',
                        homepage   => 'https://github.com/skx/slaughter/',
                        bugtracker => 'https://github.com/skx/slaughter/issues',
                        repository => 'https://github.com/skx/slaughter.git',
                        GitMirror  => 'http://git.steve.org.uk/skx/slaughter',
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
