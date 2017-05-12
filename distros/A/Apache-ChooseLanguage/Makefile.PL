use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::ChooseLanguage',
    'VERSION_FROM'	=> 'ChooseLanguage.pm',
    'ABSTRACT'		=> 'Apache mod_perl handler to manage sites available in many languages',
    'AUTHOR'		=> 'Billy Nadeau <bill@sanac.net>',
    'PREREQ_PM'		=> { "mod_perl" => 1.0,
			     "CGI::Cookie" => 0 }
);
