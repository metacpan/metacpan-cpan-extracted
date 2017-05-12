use ExtUtils::MakeMaker;

my %opts = (
    'NAME'	       => 'Class::Singleton',
    'VERSION_FROM' => 'lib/Class/Singleton.pm', # finds $VERSION
    'PMLIBDIRS'    => [ 'lib' ], 
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@wardley.org>';
    $opts{ ABSTRACT } = 'Base class for creating singleton objects',
}

WriteMakefile( %opts );

