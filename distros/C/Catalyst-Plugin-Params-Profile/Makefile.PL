use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Catalyst::Plugin::Params::Profile',
    'VERSION_FROM' => 'lib/Catalyst/Plugin/Params/Profile.pm',
    'PREREQ_PM'    => {
                    'Catalyst'              => '5.66',
                    'Params::Profile'       => '0.10',
                    'Test::More'            => '0.62',
                }
);
