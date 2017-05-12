use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'CohortExplorer',
	AUTHOR       => 'Abhishek Dixit <adixit@cpan.org>',
	VERSION_FROM => 'lib/CohortExplorer.pm',
	ABSTRACT => 'Explore clinical cohorts and search for entities of interest',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {
		'Carp'                       => 0,
		'Test::More'                 => 0,
		'CLI::Framework'             => 0.05,
		'Config::General'            => 2.50,
		'DBI'                        => 0,
		'Exception::Class::TryCatch' => 1.12,
		'FileHandle'                 => 0,
		'File::HomeDir'              => 0.98,
		'File::Spec'                 => 0,
		'HTTP::Cookies'              => 6.00,
		'JSON'                       => 2.53,
		'Log::Log4perl'              => 1.29,
		'LWP::UserAgent'             => 6.03,
		'MIME::Base64'               => 0,
		'POSIX'                      => 0,
		'SQL::Abstract::More'        => 1.17,
		'Statistics::Descriptive'    => 3.0203,
		'Text::CSV_XS'               => 0.97,
		'Text::ASCIITable'           => 0.20,
		'Time::HiRes'                => 0,
		'Tie::Autotie'               => 0,
		'Tie::IxHash'                => 1.21,
		'Term::ReadKey'              => 2.14,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'CohortExplorer-*' },
);
