use ExtUtils::MakeMaker 6.48;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	        => 'App::Module::Lister',
	'ABSTRACT_FROM' => 'lib/App/Module/Lister.pm',
	'VERSION_FROM'  => 'lib/App/Module/Lister.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0.95',
		},

	'META_MERGE' => {
        'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/app-module-lister.git',
				web  => 'https://github.com/briandfoy/app-module-lister',
				},
			},
		},

	clean  => { FILES    => q|App-Module-Lister-* *.old *.bak| },

	);
