use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::CompressClientFixup',
    'AUTHOR'            => 'Slava Bizyayev <slava@cpan.org>',
    'VERSION_FROM'	=> 'CompressClientFixup.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				'Apache::Constants' => '0',
				'Apache::Log' => '0',
				'Apache::URI' => '0',
				}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'CompressClientFixup.pm', # retrieve abstract from module
       ) : ()),
);
