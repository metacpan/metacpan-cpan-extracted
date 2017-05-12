use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Dynagzip',
    'AUTHOR'		=> 'Slava Bizyayev <slava@cpan.org>',
    'VERSION_FROM'	=> 'Dynagzip.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Apache::Constants' => '0',
				'Apache::File' => '0',
				'Apache::Log' => '0',
				'Apache::URI' => '0',
				'Apache::Util' => '0',
				'Fcntl' => '0',
				'FileHandle' => '0',
				'Compress::LeadingBlankSpaces' => '0',
				'Compress::Zlib' => '1.16',
			   }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Dynagzip.pm', # retrieve abstract from module
      ) : ()),
);
