#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'			=> 'Apache::Backend::POE',
    'VERSION_FROM'	=> 'lib/Apache/Backend/POE.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'IO::Socket::INET'		=>	undef,
		'POSIX'		=>	undef,
		'Carp'		=>	undef,
		'Storable'	=>	undef,
		'Apache'	=>	undef,
    },

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM	=> 'lib/Apache/Backend/POE.pm', # retrieve abstract from module
		 AUTHOR			=> 'David Davis <xantus@cpan.org>') : ()),
);
