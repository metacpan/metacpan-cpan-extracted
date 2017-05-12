use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Catalyst::Authentication::Credential::Flickr',
    VERSION_FROM => 'lib/Catalyst/Authentication/Credential/Flickr.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Flickr authentication for Catalyst',
    PREREQ_PM    => {
                     'Catalyst::Plugin::Authentication' => 0.10,
                     'Class::Accessor::Fast'            => 0,
                     'Flickr::API'                      => 1.00,
                     'LWP::UserAgent'                   => 5.802,
                     'Test::MockObject'                 => 0,
                     'Test::More'                       => 0,
                    },
);
