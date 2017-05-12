use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Method::CaseInsensitive',
    'VERSION_FROM'	=> 'CaseInsensitive.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	Test::Simple  => 0.45,
    },
);
