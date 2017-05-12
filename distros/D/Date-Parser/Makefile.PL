use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Date::Parser',
    VERSION_FROM    => 'lib/Date/Parser.pm',
    PREREQ_PM       => {
        'Date::Format' => '0',
    },
);
