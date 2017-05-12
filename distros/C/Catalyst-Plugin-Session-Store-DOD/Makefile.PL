use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Catalyst::Plugin::Session::Store::DOD',
    VERSION_FROM    => 'lib/Catalyst/Plugin/Session/Store/DOD.pm',
    AUTHOR          => 'David Recordon <david@sixapart.com>',
    
    PREREQ_PM       => {
        'Catalyst::Runtime'         => '5.49',
        'Catalyst::Plugin::Session' => '0.05',
        'Data::ObjectDriver'        => '0.40',
        'MIME::Base64',
        'Storable',
        'Test::More',
        'NEXT',
    }
);

1;
