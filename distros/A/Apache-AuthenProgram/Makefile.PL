use ExtUtils::MakeMaker;


# The following code to check the module and version number was borrowed



WriteMakefile(
    'NAME'	=> 'Apache::AuthenProgram',
    'VERSION_FROM' => 'AuthenProgram.pm', # finds $VERSION
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);
