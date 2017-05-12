use ExtUtils::MakeMaker;

require 5.006;

print <<'HERE';
=====================================================================
             This module is looking for a maintainer!

No one is maintaining this module, but you can take up its care
and feeding by requesting CPAN persmissions from modules@perl.org.

This version is assigned to the ADOPTME CPAN user and hosted in
GitHub:

	https://github.com/CPAN-Adopt-Me/Apache-iTunes

=====================================================================
HERE

WriteMakefile(
	'NAME'		    => 'Apache::iTunes',
	'ABSTRACT_FROM' => 'lib/Apache/iTunes.pm',

	'VERSION_FROM'  => 'lib/Apache/iTunes.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM' => {
		'Apache::Constants'   => '0',
		'Apache::FakeRequest' => '0',
		'Apache::Util'        => '0',
		'Mac::iTunes'         => '0',
		'Test::More'          => '0',
		'Text::Template'      => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/CPAN-Adopt-Me/Apache-iTunes',
				web  => 'https://github.com/CPAN-Adopt-Me/Apache-iTunes',
				},
			},
		},

	clean => { FILES => '*.bak Apache-*' },

	);
