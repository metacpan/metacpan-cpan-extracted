use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Data::Sync',
    'VERSION_FROM'      => 'lib/Data/Sync.pm', # finds $VERSION
	'MAN3PODS'	=> { },
);
