use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'AxKit::XSP::QueryParam',
    'VERSION_FROM' => 'lib/AxKit/XSP/QueryParam.pm',
    'PREREQ_PM'    => {
        Apache::Request => 0,
        Apache::AxKit::Language::XSP::TaglibHelper => 0,
    },
);
