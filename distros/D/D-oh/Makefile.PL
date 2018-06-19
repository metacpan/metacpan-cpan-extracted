use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'D::oh',
    'VERSION_FROM' => 'lib/D/oh.pm', # finds $VERSION
    'PREREQ_PM' => {
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'Carp'                  => 0,
        'IO::Handle'            => 0,
        'JSON'                  => 0,
        'Time::HiRes'           => 0,
    }
);
