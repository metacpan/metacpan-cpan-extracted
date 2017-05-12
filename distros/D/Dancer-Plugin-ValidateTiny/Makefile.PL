use ExtUtils::MakeMaker;


WriteMakefile(
    NAME => 'Dancer::Plugin::ValidateTiny',
    AUTHOR => 'Alexey Kolganov <kalgan@cpan.org>',
    VERSION_FROM => 'lib/Dancer/Plugin/ValidateTiny.pm',
    ABSTRACT_FROM => 'lib/Dancer/Plugin/ValidateTiny.pm',
    PREREQ_PM => {
        'Dancer' => 1.3050,
        'Validate::Tiny' => '1.501',
        'Email::Valid'   => '0.184',
    },
);
