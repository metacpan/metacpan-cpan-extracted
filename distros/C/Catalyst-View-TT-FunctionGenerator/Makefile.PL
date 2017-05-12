use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Catalyst::View::TT::FunctionGenerator',
    'VERSION_FROM' => 'lib/Catalyst/View/TT/FunctionGenerator.pm',
    'PREREQ_PM'    => {
        'Catalyst'           => '5.61',
        'Catalyst::View::TT' => '0.22'
    },
    'INSTALLDIRS' => 'site',
    'PL_FILES'    => {},
    'SIGN'        => 1,
);
