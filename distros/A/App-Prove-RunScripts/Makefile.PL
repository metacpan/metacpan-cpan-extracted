use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'App::Prove::RunScripts',
    VERSION_FROM  => 'lib/App/Prove/RunScripts.pm',
    AUTHOR        => 'Yoshihiro Sasaki <ysasaki at cpan.org>',
    ABSTRACT      => 'Run scripts around a TAP harness.',
    PREREQ_PM     => {
        'parent'                   => 0,
        'Class::Method::Modifiers' => '1.08',
    },
    META_MERGE => {
        resources => {
            license => 'http://dev.perl.org/licenses/',
            bugtracker =>
                'https://github.com/ysasaki/p5-app-prove-runscripts/issues',
            repository => 'git://github.com/ysasaki/p5-app-prove-runscripts.git',
        },
    },
    EXE_FILES => ['bin/prove_runscripts'],
    LICENSE   => 'perl',
);
