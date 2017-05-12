use ExtUtils::MakeMaker 6.48;

require 5.010;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'App::PPI::Dumper',
	'ABSTRACT'     => 'Use the PPI to dump the structure of a Perl file',
	'VERSION_FROM' => 'lib/App/PPI/Dumper.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM'    => {
		'ExtUtils::MakeMaker' => '6.48',
		'Getopt::Std'  => '0',
		'PPI::Dumper'  => '0',
		'PPI'          => '0',
		'Test::More'   => '0.95',
		'Test::Output' => '0',
		},

	'META_MERGE' => {
		resources => {
			repository => 'https://github.com/briandfoy/app-ppi-dumper',
			},
		},

	'EXE_FILES'    => [ 'script/ppi_dumper' ],

	clean  => { FILES    => q|App-PPI-Dumper-*| },
	);
