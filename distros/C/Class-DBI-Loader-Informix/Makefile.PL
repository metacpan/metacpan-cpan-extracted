use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    'NAME'         => 'Class::DBI::Loader::Informix',
    'VERSION'      => '1.4',
    'PL_FILES'     => {},
    'PREREQ_PM'    => {
        Test::More         => 0.32,
        DBD::Informix      => 2005.02,
        Class::DBI         => 0.89,
        Class::DBI::Loader => 0.29
    },
);
