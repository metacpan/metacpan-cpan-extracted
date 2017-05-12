use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Apache2::xForwardedFor',
    'VERSION_FROM' => 'lib/Apache2/xForwardedFor.pm', # finds $VERSION
    'PREREQ_PM' => {
        'mod_perl2'  => 0,
    },
);
