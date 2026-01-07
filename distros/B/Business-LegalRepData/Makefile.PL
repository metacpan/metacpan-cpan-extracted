use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Business::LegalRepData',
    VERSION_FROM => 'lib/Business/LegalRepData.pm',
    ABSTRACT     => 'LegalRepData-related business utilities',
    AUTHOR       => 'Lubell',
    PREREQ_PM    => {
        'URI::Escape'       => 0,
        'JSON'       => 0,
        'JSON'       => 0,
        'File::Spec' => 0,
    },
);
