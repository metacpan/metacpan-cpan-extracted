use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# $Id: Makefile.PL 86 2006-01-02 09:13:53Z roam $
WriteMakefile(
    NAME              => 'Audio::Scrobbler',
    VERSION_FROM      => 'lib/Audio/Scrobbler.pm', # finds $VERSION
    PREREQ_PM         => {
				'Config::IniFiles'	=> 2,
				'Digest::MD5'		=> 2,
				'LWP'			=> 5,
			},
    EXE_FILES         => [ qw{ bin/scrobbler-helper } ],
    ABSTRACT_FROM     => 'lib/Audio/Scrobbler.pm', # retrieve abstract from module
    AUTHOR            => 'Peter Pentchev <roam@ringlet.net>',
);
