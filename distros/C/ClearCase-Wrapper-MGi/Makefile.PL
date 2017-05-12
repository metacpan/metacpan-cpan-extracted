use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'ClearCase::Wrapper::MGi',
    'VERSION_FROM'	=> 'MGi.pm', # finds $VERSION
    'PREREQ_PM' => {
	  ClearCase::Wrapper		=> 1.00,
	  Date::Parse                   => 2.27,
    },
    'dist' => {
	  DIST_DEFAULT	=> 'all tardist',
	  COMPRESS	=> 'gzip --force --best',
	  TAR		=> 'gtar',
	  TARFLAGS	=> '--mode=u+w -cvf',
    },
);
