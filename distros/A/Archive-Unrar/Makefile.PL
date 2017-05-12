use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Archive::Unrar',
	LICENSE             => 'Artistic License',
    VERSION_FROM      => 'lib/Archive/Unrar.pm', # finds $VERSION
    PREREQ_PM         => {'Win32::API' => 0,'File::Spec' => 0,'Devel::CheckOS'=> 0,'Win32API::Registry'=>0,'Encode'=>0}, # e.g., Module::Name => 1.1
	INSTALLDIRS => 'perl',
	'dist'  => {
        COMPRESS => 'gzip -9f', 
        SUFFIX   => 'gz'
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Archive/Unrar.pm', # retrieve abstract from module
       AUTHOR         => 'Nikos Vaggalis <nikosv@cpan.org>') : ()),
);
