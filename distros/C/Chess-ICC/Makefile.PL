use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Chess::ICC',
    'VERSION_FROM'	=> 'ICC.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    'HTML::Tree' => 3.11

}, # e.g., Module::Name => 1.1
);
