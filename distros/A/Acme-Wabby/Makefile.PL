use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Acme::Wabby',
    'VERSION_FROM' => 'Wabby.pm',
    'PREREQ_PM'    => { 'Storable' => 0 },
    dist => { COMPRESS => "gzip", SUFFIX => "gz" }
);

