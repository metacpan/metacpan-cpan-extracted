use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Edit',
    VERSION_FROM      => 'lib/Data/Edit.pm', # finds $VERSION
    PREREQ_PM         => {
        'Cwd' => 0,
        'File::Temp' => 0,
        'Moose' => 0,
        'MooseX::Types::Moose' => 0,
        'File::Spec' => 0,
        'YAML::Any' => 0,
        'Try::Tiny' => 0,
    },
    BUILD_REQUIRES => {
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Edit.pm', # retrieve abstract from module
       AUTHOR         => 'Dave Lambley <davel@state51.co.uk>') : ()),
    META_MERGE => {
        resources => {
            repository => "http://github.com/davel/Data-Edit",
        },
    },
    LICENSE           => "perl",
);
