use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz'
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Data::Text',
	AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Data/Text.pm',
	ABSTRACT_FROM	   => 'lib/Data/Text.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	'LIBS' => [''],   # e.g., '-lm'
	'DEFINE' => '',     # e.g., '-DHAVE_SOMETHING'
	'INC' => '',     # e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	TEST_REQUIRES => {
		'Test::Carp' => 0,
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'Test::Needs' => 0
	}, PREREQ_PM => {
		'Carp' => 0,
		'Lingua::Conjunction' => 0,
		'overload' => 0,
		'Params::Get' => 0,
		'Scalar::Util' => 0,
		'String::Util' => 0
	}, dist => $dist,
	clean		=> { FILES => 'Data-Text-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Data-Text.git',
				web => 'https://github.com/nigelhorne/Data-Text',
				repository => 'https://github.com/nigelhorne/Data-Text',
			}, bugtracker => {
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Text',
				web => 'https://github.com/nigelhorne/Data-Text/issues',
				url => 'https://github.com/nigelhorne/Data-Text/issues',
				mailto => 'bug-Data-Text@rt.cpan.org'
			}
		},
	},
	# MIN_PERL_VERSION	=> '5.008'
);
