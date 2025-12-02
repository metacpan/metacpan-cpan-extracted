use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'AI::ActivationFunctions',
    VERSION_FROM  => 'lib/AI/ActivationFunctions.pm',
    ABSTRACT_FROM => 'lib/AI/ActivationFunctions.pm',
    AUTHOR        => 'Ulisses Manzo Castello <umcastello@gmail.com>',
    LICENSE       => 'perl_5',
    PREREQ_PM     => {
        'Test::More' => 0,
        'Exporter'   => 0,
        # PDL é recomendado, mas não obrigatório
        'PDL'        => 0,  # em Build.PL seria 'recommends'
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/seuusuario/ai-activationfunctions.git',
                web  => 'https://github.com/seuusuario/ai-activationfunctions',
            },
        },
    },
);
