use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Audio::File',
    VERSION_FROM      => 'lib/Audio/File.pm', # finds $VERSION
    PREREQ_PM         => {
			'Audio::FLAC::Header'			=> 0,
			'Ogg::Vorbis::Header::PurePerl'	=> 0,
			'MP3::Info'						=> 0,
			'MP3::Tag'						=> 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Audio/File.pm', # retrieve abstract from module
       AUTHOR         => 'Florian Ragwitz <flora@cpan.org>') : ()),
);
