use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'DateTime::Format::JSON::MicrosoftDateFormat',
    VERSION_FROM => 'lib/DateTime/Format/JSON/MicrosoftDateFormat.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/DateTime/Format/JSON/MicrosoftDateFormat.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'DateTime'     => 0,
                    },
);
