use 5.008004;
use ExtUtils::MakeMaker;
use warnings;
WriteMakefile(
    NAME              => 'Apache::FastForward',
    VERSION_FROM      => 'lib/Apache/FastForward.pm', 
    PREREQ_PM         => {
			    Text::CSV_XS => 0,
			    Encode => 0,
	 	            Apache => 0  },
    ABSTRACT_FROM  => 'lib/Apache/FastForward.pm', 
    AUTHOR         => 'Jerzy Wachowiak <jwach@cpan.org>')

