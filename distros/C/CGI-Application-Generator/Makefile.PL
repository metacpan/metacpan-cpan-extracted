use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'CGI::Application::Generator',
	'VERSION_FROM'	=> 'Generator.pm', # finds $VERSION
	'PREREQ_PM'		=> {
		'CGI::Application' => 3,
		'HTML::Template' => 2.6,
	},
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'Generator.pm', # retrieve abstract from module
		AUTHOR     => 'Jesse Erlbaum <jesse@erlbaum.net>') : ()),
	'PM' => {
		'Generator.pm' => '$(INST_LIBDIR)/Generator.pm',
		'app_module.tmpl' => '$(INST_LIBDIR)/Generator/app_module.tmpl',
	},
);
