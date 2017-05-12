use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Acme::Code::Police',
    'VERSION_FROM' => 'lib/Acme/Code/Police.pm',
    'PREREQ_PM'    => {},
    (
        $] >= 5.005
        ? ( AUTHOR => 'Curtis "Ovid" Poe <ovid [at] cpan [dot] org>' )
        : ()
    ),
);
