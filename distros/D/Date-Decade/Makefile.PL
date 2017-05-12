use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval { require 5.003_03 }
	or die <<EOL;
# This Module requires lvaluable subroutines, which are not avaiable
# in the version of Perl earlier than 5.003_03. Please upgrade!
EOL

WriteMakefile (
	'NAME'		=> 'Date::Decade',
	'VERSION_FROM'	=> 'Decade.pm', # finds $VERSION
#	'PREREQ_PM'	=> { 'Date::Pcalc' => 1.2 },
	'PREREQ_PM'	=> { 'Date::Calc' => 4.3 },
);
