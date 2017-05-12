use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Apache::Syntax::Highlight::Perl',
	VERSION_FROM      => 'lib/Apache/Syntax/Highlight/Perl.pm', # finds $VERSION
	PREREQ_PM         => {
                         'mod_perl'                => 1.24,
                         'Syntax::Highlight::Perl' => 1.00                
                        }, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'lib/Apache/Syntax/Highlight/Perl.pm', # retrieve abstract from module
		 AUTHOR        => 'Enrico Sorcinelli <enrico@sorcinelli.it>') : ()),
);
