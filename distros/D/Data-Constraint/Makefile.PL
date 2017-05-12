use ExtUtils::MakeMaker 6.48;

require 5.006;

eval "use Test::Manifest 2.01";

WriteMakefile
	(
	'NAME'          => 'Data::Constraint',
	'ABSTRACT'      => 'prototypical value checking',
	'VERSION_FROM'  => 'lib/Data/Constraint.pm',
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',
 	
	'PREREQ_PM' => {
		'Test::More'        => '0.95',
		'Class::Prototyped' => '0',
		},

	MIN_PERL_VERSION => 5.006,

	META_MERGE => {
			resources => {
				bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Constraint',
		  		repository => 'git://github.com/briandfoy/data-constraint.git',
				},
			keywords => [ 'module', 'distribution', 'test' ],
	  		},
	
	clean => { FILES => 'Data-* *.bak *.old' },
	);
        
1;
