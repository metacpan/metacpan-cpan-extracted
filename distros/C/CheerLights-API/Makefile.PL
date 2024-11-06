use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'CheerLights::API',
    VERSION_FROM => 'CheerLights/API.pm',
    AUTHOR       => 'Hans Scharler <nothans@cpan.org>',
    ABSTRACT     => 'A Perl module for accessing the CheerLights API',
    PREREQ_PM    => {
        'LWP::UserAgent' => 0,
        'JSON'           => 0,
    },
);
