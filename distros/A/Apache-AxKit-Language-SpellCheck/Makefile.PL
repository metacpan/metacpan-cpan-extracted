use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Apache::AxKit::Language::SpellCheck',
    'VERSION_FROM' => 'SpellCheck.pm',
    'PREREQ_PM'    => {
        'AxKit'        => 1.6,
        'Text::Aspell' => 0.04,
    },
);
