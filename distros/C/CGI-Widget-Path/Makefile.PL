use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'          => 'CGI::Widget::Path',
	'AUTHOR'        => 'Enrico Sorcinelli <enrico@sorcinelli.it>',
	'ABSTRACT_FROM' => 'Path.pm',
	'VERSION_FROM'  => 'Path.pm', # finds $VERSION
	'PREREQ_PM'     => {}, # e.g., Module::Name => 1.1
);
