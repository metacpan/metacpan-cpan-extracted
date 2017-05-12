use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Apache::AuthzUserDir',
    'VERSION_FROM' => 'AuthzUserDir.pm', # finds $VERSION
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'}
);
