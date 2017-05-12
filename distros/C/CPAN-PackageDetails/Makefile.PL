use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.23";

WriteMakefile(
	'NAME'	       => 'CPAN::PackageDetails',
	'ABSTRACT'     => "Create or read PAUSE's 02packages.details.txt.gz",
	'VERSION_FROM' => 'lib/CPAN/PackageDetails.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM'    => {
		'CPAN::DistnameInfo'     => '0',
#		'DBM::Deep'              => '0',
		'Test::More'             => '0',
		'Test::Output'           => '0.10',
		'IO::Compress::Gzip'     => '0',
		'IO::Uncompress::Gunzip' => '0',
		'version'                => '0.78',
		},

	'META_MERGE'   => {
		'meta-spec' => { version => '2' },
		'resources' => {
			'repository' => {
				type => 'git',
				web  => 'https://github.com/briandfoy/cpan-packagedetails',
				url  => 'git@github.com:briandfoy/cpan-packagedetails.git',
				},
			},
		},

	clean  => { FILES    => q|CPAN-PackageDetails-* t/test_output| },
	);
